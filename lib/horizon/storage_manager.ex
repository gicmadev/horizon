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
  end

  def store!(file) do
    sha256 = get_sha256(file.path)

    {:ok, asset} =
      Repo.transaction(fn ->
        asset =
          Repo.insert!(
            Asset.changeset(%Asset{}, %{
              filename: file.filename,
              content_type: MIME.from_path(file.filename),
              sha256: sha256,
              status: :processing
            })
          )

        Mirage.store!(file, asset)

        asset
      end)

    GenServer.cast(__MODULE__, {:process_asset, asset})

    {:ok, asset}
  end

  def download!(asset_id, sha256) do
    assets = Asset.get_asset_and_blobs(asset_id, sha256)

    mirage_blob = Enum.find(assets, fn a -> a.storage === :mirage end)

    if mirage_blob !== nil do
      {:downloaded, Mirage.get_blob_path(mirage_blob)}
    else
      raise "not yet implemented"
    end

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
