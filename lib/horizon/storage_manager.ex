defmodule Horizon.StorageManager do
  use GenServer

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

  def new! do
    Repo.insert(%Upload{status: :new})
  end

  def store!(upload_id, file) do
    asset = Repo.get_by!(Upload, id: upload_id, status: :new)

    sha256 = get_sha256(file.path)
    %{size: size} = File.stat!(file.path)

    {:ok, _} =
      Repo.transaction(fn ->
        upload =
          upload
          |> Upload.changeset(%{
            filename: file.filename,
            content_type: MIME.from_path(file.filename),
            sha256: sha256,
            size: size,
            status: :draft
          })
          |> Repo.update!()

        Mirage.store!(file, upload)
      end)

    {:ok, upload}
  end

  def cancel!(upload_id) do
    Repo.get_by!(
      Upload,
      id: upload_id,
      status: :new
    )
    |> Repo.delete!()

    {:ok, :deleted}
  end

  def remove!(upload_id) do
    Repo.get!(
      Upload,
      upload_id
    )
    |> Repo.delete!()

    {:ok, :deleted}
  end

  def burn!(upload_id) do
    upload = Repo.get!(Upload, upload_id)

    upload =
      upload
      |> Upload.changeset(%{
        status: :processing
      })
      |> Repo.update!()

    # start processing here

    {:ok, upload}
  end

  def download!(ash_id) do
    {upload_id, sha256} = parse_ash_id(ash_id)

    blobs = Upload.get_upload_and_blobs(upload_id, sha256)

    mirage_blob = Enum.find(blobs, fn a -> a.storage === :mirage end)

    if mirage_blob !== nil do
      {:downloaded, Mirage.get_blob_path(mirage_blob)}
    else
      raise "not yet implemented"
    end
  end

  def get!(upload_id) do
    case Repo.get(Upload, upload_id) do
      nil -> nil
      upload -> {:ok, upload}
    end
  end

  def status(ash_id) do
    IO.inspect(ash_id)

    {upload_id, sha256} = parse_ash_id(ash_id)

    blobs = Upload.get_upload_and_blobs(upload_id, sha256)

    %{filename: filename, status: status} = List.first(blobs)

    %{filename: filename, status: status, storages: Enum.map(blobs, fn a -> a.storage end)}
  end

  defp parse_ash_id(ash_id) do
    IO.inspect(ash_id)

    [upload_id, sha256] = String.split(ash_id, ".", parts: 2)

    IO.inspect(upload_id)
    IO.inspect(sha256)

    {upload_id, _} = Integer.parse(upload_id)

    IO.inspect(upload_id)

    true = String.match?(sha256, ~r/[A-Fa-f0-9]{64}/)

    IO.inspect(sha256)

    {upload_id, sha256}
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:process_upload, upload}, state) do
    IO.inspect(upload, label: "process_upload")

    upload =
      Repo.update!(
        Upload.changeset(upload, %{
          status: :ok
        })
      )

    IO.inspect(upload, label: "processed upload")

    {:noreply, state}
  end

  defp get_sha256(file_path) do
    File.stream!(file_path, [], 2_048)
    |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end
end
