defmodule Horizon.DownloadManager.Download do
  use GenServer
  require Logger

  alias Horizon.DownloadManager.DownloadStream
  alias Horizon.DownloadManager.Downloader

  @registry :downloads_registry

  ## API
  def start_link(url, path, expected_size),
    do: GenServer.start_link(__MODULE__, {url, path, expected_size}, name: via_tuple(url))

  ## Callbacks
  def init({url, path, expected_size}) do
    Logger.info("Starting download of #{inspect(url)}")

    case spawn_downloader(url, path) do
      {:ok, _pid} ->
        Logger.info("Started download of #{inspect(url)}")
        {:ok, {:started, %{url: url, path: path, expected_size: expected_size}, %{}}}

      err ->
        {:errored, err}
    end
  end

  def get_status(url) do
    GenServer.call(via_tuple(url), :status)
  end

  def get_download_stream(url) do
    GenServer.call(via_tuple(url), :get_download_stream)
  end

  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_download_stream, _from, state) do
    {_, %{url: url, path: path, expected_size: expected_size}, _} = state

    {:reply, %DownloadStream{url: url, path: path, full_size: expected_size}, state}
  end

  def handle_info({:update_progress, {:downloaded_bytes, bytes}}, state) do
    {status, request, progress} = state

    {:noreply, {status, request, Map.put(progress, :downloaded, &(&1 + bytes))}}
  end

  def handle_info({:update_progress, {:content_length, bytes}}, state) do
    {status, request, progress} = state

    {:noreply, {status, request, Map.put(progress, :content_length, bytes)}}
  end

  def handle_info({:update_status, :finished}, state) do
    {_, request, progress} = state

    Logger.info("Finished download of #{inspect(request.url)}")

    {:stop, :normal, {:finished, request, progress}}
  end

  def handle_info({:update_status, {:errored, reason}}, state) do
    {_, request, progress} = state

    Logger.error("Download of #{inspect(request.url)} ERRORED : #{inspect(reason)}")

    {:stop, :normal, {:errored, request, progress}}
  end

  def handle_info({:update_status, {:crashed, reason}}, state) do
    {_, request, progress} = state

    Logger.error("Download of #{inspect(request.url)} CRASHED")

    {:stop, reason, {:crashed, request, progress}}
  end

  def handle_info({:update_status, status}, state) do
    {_, request, progress} = state

    Logger.info("Download of #{inspect(request.url)} status changed to #{inspect(status)}")

    {:noreply, {status, request, progress}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  ## Private
  defp via_tuple(url),
    do: {:via, Registry, {@registry, url}}

  defp spawn_downloader(url, path) do
    opts = %{
      download_pid: self(),
      path: path,
      url: url
    }

    {:ok, spawn_link(Downloader, :run, [opts])}
  end
end
