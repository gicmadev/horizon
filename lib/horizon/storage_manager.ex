defmodule Horizon.StorageManager do
  @moduledoc """
  Provides Storage functions
  """

  use GenServer

  require Logger

  import Ecto.Query

  alias Horizon.StorageManager.Provider.{Mirage}

  alias Horizon.Repo
  alias Horizon.Schema.Upload

  def start_link(_opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      {},
      name: __MODULE__
    )
  end


  @clean_uploads_interval 1 * 3_600 * 1_000


  # Server (callbacks)
  @impl true
  def init(_) do
    Process.send_after(self(), :clean_uploads, 1_000)

    {:ok, %{last_clean_uploads_at: nil}}
  end

  @impl true
  def handle_info(:clean_uploads, state) do
    clean_uploads()

    Process.send_after(self(), :clean_uploads, @clean_uploads_interval)

    {:noreply, Map.merge(state, %{last_clean_uploads_at: :calendar.local_time()})}
  end

  def clean_uploads do
    from(u in Upload, where: u.status == ^:draft and u.updated_at < ago(36, "hour"))
    |> Repo.all
    |> Enum.each(&reset_and_unstore!/1)
    |> Repo.delete_all

    from(u in Upload, where: u.status == ^:new and u.updated_at < ago(24, "hour"))
    |> Repo.delete_all
  end

  def new!(params) do
    upload = Upload.new(params)
    Repo.insert(upload)
  end

  def upload_for_source(source) do
    Repo.get_by(Upload, source: source)
  end

  def store!(upload_id, file) do
    upload = Repo.get_by!(Upload, id: upload_id, status: :new)

    new_path = "#{file.path}#{:filename.extension(file.filename)}"

    File.rename!(file.path, new_path)

    file = %{file | path: new_path}

    %{size: size} = File.stat!(file.path)
    sha256 = get_sha256(file.path)

    upload_data = %{
      filename: file.filename,
      content_type: MIME.from_path(file.filename),
      sha256: sha256,
      content_length: size,
    }

    upload_data = case Taglib.new(file.path) do
      {:ok, tags} -> 
        Map.merge(upload_data, %{
          duration: Taglib.duration(tags),
          artwork: case Taglib.artwork(tags) do
            {mimetype, binart} -> "data:#{mimetype};base64,#{Base.encode64(binart)}"
            _ -> nil
          end
        })
      err -> 
        Logger.error("Error inspecting taglib for #{file.path} : #{inspect err}")
        upload_data
    end

    {:ok, _} =
      Repo.transaction(fn ->
        upload =
          upload
          |> Upload.upload(upload_data)
          |> Repo.update!()

        Mirage.store!(file, upload)

        File.rm!(file.path) # remove temp file
      end)

    {:ok, upload}
  end

  def revert!(upload_id) do
    {:ok, _} = from(u in Upload, where: u.id == ^upload_id and u.status in [^:new, ^:draft]) 
               |> Repo.one!
               |> reset_and_unstore!

    {:ok, :reverted}
  end

  def remove!(upload_id) do
    {:ok, _} = Repo.get!(Upload, upload_id) |> reset_and_unstore!

    {:ok, :deleted}
  end

  def clear_bucket!(bucket_id) do
    from(u in Upload, where: u.bucker == ^bucket_id)
    |> Repo.all
    |> Enum.each(&reset_and_unstore!/1)
    |> Repo.delete_all
  end

  defp reset_and_unstore!(upload) do
    Repo.transaction(fn ->
      Mirage.unstore!(upload)

      Upload.reset(upload)
      |> Repo.update!
    end)
  end

  def burn!(upload_id) do
    Repo.get!(Upload, upload_id)
    |> Upload.burn()
    |> Repo.update!

    {:ok, :burnt}
  end

  def download!(upload_id) do
    case Upload.get_upload_and_blobs(upload_id) do
      [] -> nil

      blobs ->
        mirage_blob = Enum.find(blobs, fn a -> a.storage === :mirage end)

        if mirage_blob !== nil do
          file_path = Mirage.get_blob_path(mirage_blob)

          %{size: file_size} = File.stat!(file_path)

          {:downloaded, file_path, file_size, mirage_blob.content_type}
        else
          raise "not yet implemented"
        end
    end

  end

  def get!(upload_id) do
    upload = from(u in Upload, where: u.id == ^upload_id and u.status != ^:new) |> Repo.one!

    {:ok, upload}
  end

  def status(upload_id) do
    blobs = Upload.get_upload_and_blobs(upload_id)

    %{filename: filename, status: status} = List.first(blobs)

    %{filename: filename, status: status, storages: Enum.map(blobs, fn a -> a.storage end)}
  end

  def storage_status(owner \\ nil) do
    query = """
      SELECT 
        bucket as feed_id, 
        CEIL(SUM(content_length))::BIGINT AS total_size, 
        SUM(duration) as total_duration, 
        COUNT(owner) as episodes_count 
      FROM public.uploads 
      WHERE status='ok'%ADD_OWNER_CLAUSE%
      GROUP BY bucket;
    """ |> add_owner_clause(owner)

    results = Ecto.Adapters.SQL.query!(
      Horizon.Repo, 
      query,
      Enum.reject([owner], &is_nil/1)
    )

    feeds = results.rows |> Enum.map(fn row -> Enum.zip(results.columns, row) |> Map.new end)

    query = """
      SELECT
        CEIL(SUM(content_length))::BIGINT AS recent_size,
        CEIL(
          SUM(content_length)
          /
          EXTRACT(
            epoch FROM (
              CASE WHEN MAX(inserted_at) = MIN(inserted_at)
              THEN (interval '12 month')
              ELSE (MAX(inserted_at) - MIN(inserted_at))
              END
            )
          )
        ) as recent_speed,
        COUNT(inserted_at) as recent_count
      FROM public.uploads
      WHERE 
        inserted_at > date_trunc(
          'day', NOW() - interval '12 month'
      ) AND status='ok'%ADD_OWNER_CLAUSE%;
      """ |> add_owner_clause(owner)

    results = Ecto.Adapters.SQL.query!(
      Horizon.Repo,
      query,
      Enum.reject([owner], &is_nil/1)
    )

    resp = results.rows 
           |> Enum.map(fn row -> Enum.zip(results.columns, row) |> Map.new end) 
           |> List.first 
           |> Map.merge(%{feeds: feeds})

    {:ok, resp}
  end

  defp get_sha256(file_path) do
    File.stream!(file_path, [], 2_048)
    |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end

  defp add_owner_clause(query, nil) do
    query |> String.replace("%ADD_OWNER_CLAUSE%", "")
  end

  defp add_owner_clause(query, _owner) do
    query |> String.replace("%ADD_OWNER_CLAUSE%", "AND owner=$1")
  end
end
