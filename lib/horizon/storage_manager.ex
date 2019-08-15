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

  def store_file!(file) do
    sha256 = get_sha256(file.path)

    {:ok, asset} =
      Repo.transaction(fn ->
        asset =
          Repo.insert!(
            Asset.changeset(%Asset{}, %{
              filename: file.filename,
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
