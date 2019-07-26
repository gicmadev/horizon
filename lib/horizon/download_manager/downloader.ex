defmodule Horizon.DownloadManager.Downloader do
  alias HTTPoison.{AsyncHeaders, AsyncStatus, AsyncChunk, AsyncEnd}

  @wait_timeout 5000

  def run(opts) do
    File.rm(opts.path)

    with {:ok, file} <- File.open(opts.path, [:write, :exclusive]),
         {:ok, _request} <- HTTPoison.get(opts.url, %{}, stream_to: self()) do
      opts = Map.put(opts, :file, file)
      do_download(opts)
    else
      {:error, reason} ->
        unless reason === :eexist do
          File.rm!(opts.path)
        end

        send(opts.download_pid, {:update_status, {:errored, reason}})

      _ ->
        send(opts.download_pid, {:update_status, {:crashed, :unknown}})
        {:error}
    end
  end

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
      opts.download_pid,
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
        opts.download_pid,
        {:update_progress, {:content_length, String.to_integer(content_length)}}
      )
    end

    do_download(opts)
  end

  defp handle_response_chunk(%AsyncChunk{chunk: data}, opts) do
    IO.binwrite(opts.file, data)

    send(opts.download_pid, {:update_progress, {:downloaded_bytes, byte_size(data)}})

    do_download(opts)
  end

  defp handle_response_chunk(%AsyncEnd{}, opts), do: finish_download({:ok}, opts)

  defp finish_download(state, opts) do
    File.close(opts.file)

    case state do
      {:error} ->
        File.rm!(opts.path)

        send(
          opts.download_pid,
          {:update_status, {:errored, :unknown}}
        )

      {:error, reason} ->
        File.rm!(opts.path)

        send(
          opts.download_pid,
          {:update_status, {:errored, reason}}
        )

      _ ->
        send(opts.download_pid, {:update_status, :finished})
    end
  end
end
