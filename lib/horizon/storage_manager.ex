defmodule Horizon.StorageManager do
  use GenServer

  alias Horizon.StorageManager.Provider.{Horizon}

  @providers [
    Horizon
  ]

  def start_link(_opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      @providers
      |> Enum.reduce(%{}, &Map.put(&2, &1.name, &1)),
      name: __MODULE__
    )
  end

  def get_providers() do
    GenServer.call(__MODULE__, :get_providers)
  end

  # Server (callbacks)

  @impl true
  def init(providers) do
    {:ok, providers}
  end

  @impl true
  def handle_call(:get_providers, _from, providers) do
    {:reply, providers, providers}
  end
end
