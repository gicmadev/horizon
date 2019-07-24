defmodule Horizon.DownloadManager.Download do
  use GenServer
  require Logger

  @registry :downloads_registry

  ## API
  def start_link(url),
    do: GenServer.start_link(__MODULE__, url, name: via_tuple(url))

  ## Callbacks
  def init(url) do
    Logger.info("Starting download of #{inspect(url)}")

    path = "/downloads/" <> (:crypto.hash(:sha256, url) |> Base.encode16() |> String.downcase())

    with {:ok, file} <- create_file(path),
         {:ok, response_parser_pid} <- spawn_response_parser(url, file, path),
         {:ok, _pid} <- start_download(url, response_parser_pid, path) do
      {:ok, {:started, url, %{downloaded: 0}}}
    else
      err -> {:errored, err}
    end
  end

  def status(url) do
    GenServer.call(via_tuple(url), :status)
  end

  def handle_call(:status, _from, state) do
    {_, _, progress} = state
    {:reply, progress, state}
  end

  def handle_info({:update_progress, {:downloaded_bytes, bytes}}, state) do
    {status, url, progress} = state
    {:noreply, {status, url, Map.update!(progress, :downloaded, &(&1 + bytes))}}
  end

  def handle_info({:update_progress, {:content_length, bytes}}, state) do
    {status, url, progress} = state
    {:noreply, {status, url, Map.put(progress, :content_length, bytes)}}
  end

  def handle_info({:update_status, :download_finished}, state) do
    {_, url, progress} = state

    Logger.info("Finished download of #{inspect(url)}")

    {:stop, :normal, {:download_finished, url, progress}}
  end

  def handle_info({:update_status, status}, state) do
    {_, url, progress} = state

    Logger.info("Download of #{inspect(url)} status changed to #{inspect(status)}")

    {:noreply, {status, url, progress}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  ## Private
  defp via_tuple(url),
    do: {:via, Registry, {@registry, url}}

  defp create_file(path), do: File.open(path, [:write, :exclusive])

  defp spawn_response_parser(url, file, path) do
    opts = %{
      file: file,
      controlling_pid: self(),
      path: path,
      url: url
    }

    {:ok, spawn_link(__MODULE__, :do_download, [opts])}
  end

  defp start_download(url, response_parsing_pid, path) do
    request = HTTPoison.get(url, %{}, stream_to: response_parsing_pid)

    case request do
      {:error, _reason} ->
        File.rm!(path)

      _ ->
        nil
    end

    request
  end

  alias HTTPoison.{AsyncHeaders, AsyncStatus, AsyncChunk, AsyncEnd}

  @wait_timeout 5000

  @doc false
  def do_download(opts) do
    receive do
      response_chunk -> handle_response_chunk(response_chunk, opts)
    after
      @wait_timeout -> {:error, :timeout_failure}
    end
  end

  defp handle_response_chunk(%AsyncStatus{code: 200}, opts) do
    send(
      opts.controlling_pid,
      {:update_status, :downloading}
    )

    do_download(opts)
  end

  defp handle_response_chunk(%AsyncStatus{code: status_code}, opts) do
    finish_download({:error, :unexpected_status_code, status_code}, opts)
  end

  defp handle_response_chunk(%AsyncHeaders{headers: headers}, opts) do
    content_length_header =
      Enum.find(headers, fn {header_name, _value} ->
        header_name == "Content-Length"
      end)

    if content_length_header do
      {_, content_length} = content_length_header

      send(
        opts.controlling_pid,
        {:update_progress, {:content_length, String.to_integer(content_length)}}
      )
    end

    do_download(opts)
  end

  defp handle_response_chunk(%AsyncChunk{chunk: data}, opts) do
    IO.binwrite(opts.file, data)

    send(opts.controlling_pid, {:update_progress, {:downloaded_bytes, byte_size(data)}})

    do_download(opts)
  end

  defp handle_response_chunk(%AsyncEnd{}, opts), do: finish_download({:ok}, opts)

  defp finish_download(reason, opts) do
    File.close(opts.file)

    if elem(reason, 0) == :error do
      File.rm!(opts.path)

      send(
        opts.controlling_pid,
        {:update_status, :errored}
      )
    else
      send(opts.controlling_pid, {:update_status, :download_finished})
    end
  end
end
