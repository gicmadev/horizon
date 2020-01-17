defmodule Horizon.StorageManager do
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

  def new!(params) do
    upload = Upload.new(params)
    Logger.debug("upload : #{inspect upload}")
    Repo.insert(upload)
  end

  def upload_for_source(source) do
    Repo.get_by(Upload, source: source)
  end

  def store!(upload_id, file) do
    upload = Repo.get_by!(Upload, id: upload_id, status: :new)

    Logger.debug("RENAME TO : #{file.path}")

    new_path = "#{file.path}#{:filename.extension(file.filename)}"
    Logger.debug("RENAME TO : #{new_path}")

    File.rename!(file.path, new_path)

    file = %{file | path: new_path}

    Logger.debug(" file : #{inspect file}")

    %{size: size} = File.stat!(file.path)
    sha256 = get_sha256(file.path)

    upload_data = %{
      filename: file.filename,
      content_type: MIME.from_path(file.filename),
      sha256: sha256,
      content_length: size,
    }

    Logger.debug(" file : #{inspect upload_data}")

    upload_data = case Taglib.new(file.path) do
      {:ok, tags} -> 
        Map.merge(upload_data, %{
          duration: Taglib.duration(tags),
          artwork: case Taglib.artwork(tags) do
            {mimetype, binart} -> "data:#{mimetype};base64,#{Base.encode64(binart)}"
            _ -> nil
          end
        })
      eh -> 
        Logger.debug("Hey hey #{inspect eh}")
        upload_data
    end

    {:ok, _} =
      Repo.transaction(fn ->
        upload =
          upload
          |> Upload.upload(upload_data)
          |> Repo.update!()

        Mirage.store!(file, upload)

        File.rm!(file.path)
      end)

    {:ok, upload}
  end

  def revert!(upload_id) do
    from(u in Upload, where: u.id == ^upload_id and u.status in [^:new, ^:draft])
    |> Repo.one!
    |> Upload.reset
    |> Repo.update!


    {:ok, :reverted}
  end

  def remove!(upload_id) do
    Repo.get!(
      Upload,
      upload_id
    )
    |> Upload.reset
    |> Repo.update!

    {:ok, :deleted}
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
    response = %{}

    query = """
      SELECT 
        bucket as feed_id, 
        CEIL(SUM(content_length))::INTEGER AS total_size, 
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
        CEIL(SUM(content_length))::INTEGER AS recent_size,
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

  defp add_owner_clause(query, nil) do
    query |> String.replace("%ADD_OWNER_CLAUSE%", "")
  end

  defp add_owner_clause(query, owner) do
    query |> String.replace("%ADD_OWNER_CLAUSE%", "AND owner=$1")
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  defp get_sha256(file_path) do
    File.stream!(file_path, [], 2_048)
    |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end
end
