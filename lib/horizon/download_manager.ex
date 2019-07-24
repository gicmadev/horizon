defmodule Horizon.DownloadManager do
  use Supervisor

  alias Horizon.DownloadManager.DownloadsSupervisor
  alias Horizon.DownloadManager.Download

  @registry :downloads_registry
  @downloads_supervisor DownloadsSupervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {DynamicSupervisor, name: @downloads_supervisor, strategy: :one_for_one},
      {Registry, [keys: :unique, name: @registry]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def download(url) do
    DynamicSupervisor.start_child(
      @downloads_supervisor,
      %{id: Download, start: {Download, :start_link, [url]}, restart: :temporary}
    )
  end
end
