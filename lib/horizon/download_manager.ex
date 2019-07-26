defmodule Horizon.DownloadManager do
  use Supervisor

  alias Horizon.DownloadManager.{DownloadsSupervisor, Download}

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

  defp get_path_from_url(url),
    do: "/downloads/" <> (:crypto.hash(:sha256, url) |> Base.encode16() |> String.downcase())

  def ensure_downloaded(url, expected_size) do
    if Enum.empty?(Registry.lookup(@registry, url)) do
      path = get_path_from_url(url)
      file_stat = File.stat(path)

      case file_stat do
        {:ok, %{size: ^expected_size}} ->
          {:downloaded, path}

        _ ->
          download(url, path, expected_size)
      end
    else
      case Download.get_status(url) do
        {:downloading, _, _} ->
          {:downloading, Download.get_download_stream(url)}

        _ ->
          :timer.sleep(100)
          ensure_downloaded(url, expected_size)
      end
    end
  end

  defp download(url, path, expected_size) do
    DynamicSupervisor.start_child(
      @downloads_supervisor,
      %{
        id: Download,
        start: {Download, :start_link, [url, path, expected_size]},
        restart: :temporary
      }
    )

    ensure_downloaded(url, expected_size)
  end
end
