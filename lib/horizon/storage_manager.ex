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

    new_path = "#{file.path}-#{file.filename}"
    File.rename!(file.path, new_path)
    file = %{file | path: new_path}

    sha256 = get_sha256(file.path)
    %{size: size} = File.stat!(file.path)

    upload_data = %{
            filename: file.filename,
            content_type: MIME.from_path(file.filename),
            sha256: sha256,
            content_length: size,
          }


    upload_data = case Taglib.new(file.path) do
      {:ok, tags} -> 
        Logger.debug("Hey ho #{inspect tags}")
        Logger.debug("Hey ho #{inspect Taglib.props(tags)}")
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
          {:downloaded, Mirage.get_blob_path(mirage_blob)}
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
