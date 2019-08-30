defmodule Horizon.StorageManager do
  use GenServer

  alias Horizon.StorageManager.Provider.{Mirage}

  alias Horizon.Repo
  alias Horizon.Schema.Asset

  def start_link(_opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      {},
      name: __MODULE__
    )
  nd

  def new! do
    {:ok, asset} = Repo.insert(%Asset{status: :new})
    asset
  end

  def store!(asset_id, file) do
    asset = Repo.get_by!(Asset, id: asset_id, status: :new)

    sha256 = get_sha256(file.path)
    %{size: size} = File.stat!(file.path)

    {:ok, _} =
      Repo.transaction(fn ->
        asset =
          asset
          |> Asset.changeset(%{
            filename: file.filename,
            content_type: MIME.from_path(file.filename),
            sha256: sha256,
            size: size,
            status: :draft
          })
          |> Repo.update!()

        Mirage.store!(file, asset)
      end)

    {:ok, asset}
  end

  def cancel!(asset_id) do
    Repo.get_by!(
      Asset,
      id: asset_id,
      status: :new
    )
    |> Repo.delete!()

    {:ok, :deleted}
  end

  def remove!(asset_id) do
    Repo.get!(
      Asset,
      asset_id
    )
    |> Repo.delete!()

    {:ok, :deleted}
  end

  def burn!(asset_id) do
    asset = Repo.get!(Asset, asset_id)

    asset =
      asset
      |> Asset.changeset(%{
        status: :processing
      })
      |> Repo.update!()

    # start processing here

    {:ok, asset}
  end

  def download!(ash_id) do
    {asset_id, sha256} = parse_ash_id(ash_id)

    blobs = Asset.get_asset_and_blobs(asset_id, sha256)

    mirage_blob = Enum.find(blobs, fn a -> a.storage === :mirage end)

    if mirage_blob !== nil do
      {:downloaded, Mirage.get_blob_path(mirage_blob)}
    else
      raise "not yet implemented"
    end
  end

  def status(ash_id) do
    IO.inspect(ash_id)

    {asset_id, sha256} = parse_ash_id(ash_id)

    blobs = Asset.get_asset_and_blobs(asset_id, sha256)

    %{filename: filename, status: status} = List.first(blobs)

    %{filename: filename, status: status, storages: Enum.map(blobs, fn a -> a.storage end)}
  end

  defp parse_ash_id(ash_id) do
    IO.inspect(ash_id)

    [asset_id, sha256] = String.split(ash_id, ".", parts: 2)

    IO.inspect(asset_id)
    IO.inspect(sha256)

    {asset_id, _} = Integer.parse(asset_id)

    IO.inspect(asset_id)

    true = String.match?(sha256, ~r/[A-Fa-f0-9]{64}/)

    IO.inspect(sha256)

    {asset_id, sha256}
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:process_asset, asset}, state) do
    IO.inspect(asset, label: "process_asset")

    asset =
      Repo.update!(
        Asset.changeset(asset, %{
          status: :ok
        })
      )

    IO.inspect(asset, label: "processed asset")

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
