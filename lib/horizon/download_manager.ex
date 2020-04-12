defmodule Horizon.DownloadManager do
  use Supervisor

  alias Horizon.DownloadManager.{DownloadsSupervisor, Download}

  @registry :downloads_registry
  @downloads_supervisor DownloadsSupervisor

  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    File.mkdir_p!(dl_dir())

    children = [
      {DynamicSupervisor, name: @downloads_supervisor, strategy: :one_for_one},
      {Registry, [keys: :unique, name: @registry]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def download(url, opts \\ []) do
    {status, _, _} = Download.get_status(url)

    Logger.debug("this is the status for url #{inspect(url)}")
    Logger.debug("this is the status #{inspect(status)}")

    if status == :not_found do
      opts =
        opts
        |> Keyword.put(
          :path,
          Path.join(
            dl_dir(),
            :crypto.hash(:sha256, url)
            |> Base.encode16()
            |> String.downcase()
          )
        )

      Logger.debug("Starting child")
      Logger.debug("url : #{inspect(url)}")
      Logger.debug("opts : #{inspect(opts)}")

      result =
        DynamicSupervisor.start_child(
          @downloads_supervisor,
          %{
            id: Download,
            start: {Download, :start, [url, Enum.into(opts, %{})]},
            restart: :temporary
          }
        )

      Logger.debug("result : #{inspect(result)}")
    end

    get_status(url)
  end

  def get_status(url) do
    Download.get_status(url)
  end

  defp dl_dir, do: Application.get_env(:horizon, Horizon.DownloadManager)[:dl_path]
end
