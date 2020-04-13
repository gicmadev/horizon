defmodule Horizon.DownloadManager.Downloader do
  alias HTTPoison.{AsyncHeaders, AsyncRedirect, AsyncStatus, AsyncChunk, AsyncEnd}

  require Logger

  @wait_timeout 5000

  def run(opts) do
    Logger.debug("Running downloader with opts #{inspect(opts)}")

    File.rm(opts.path)

    with {:ok, file} <- File.open(opts.path, [:write, :exclusive]),
         {:ok, _req} <- do_request(opts.url) do
      opts = Map.put(opts, :file, file)
      do_download(opts)
    else
      {:error, reason} ->
        unless reason === :eexist do
          File.rm(opts.path)
        end

        send(opts.download_pid, {:update_status, {:errored, reason}})

      _ ->
        send(opts.download_pid, {:update_status, {:crashed, :unknown}})
        {:error}
    end
  end

  defp do_request(url) do
    Logger.debug("Starting GET request to #{url} with stream_to #{inspect(self())}")
    req = HTTPoison.get(url, %{}, stream_to: self(), follow_redirect: true)
    Logger.debug("#{inspect(req)}", label: "request")
    req
  end

  defp do_download(opts) do
    receive do
      response_chunk ->
        handle_response_chunk(response_chunk, opts)
    after
      @wait_timeout -> finish_download({:error, :timeout_failure}, opts)
    end
  end

  defp handle_response_chunk(%AsyncRedirect{to: to}, opts) do
    Logger.debug("Redirecting to #{to}")

    send(
      opts.download_pid,
      {:update_status, :redirecting}
    )

    do_request(to)
    do_download(opts |> Map.put(:url, to))
  end

  defp handle_response_chunk(%AsyncStatus{code: 200}, opts) do
    send(
      opts.download_pid,
      {:update_status, :downloading}
    )

    do_download(opts)
  end

  defp handle_response_chunk(%AsyncStatus{code: status_code}, opts) do
    finish_download({:error, {:unexpected_status_code, status_code}}, opts)
  end

  defp check_content_type(headers) do
    [content_type | _] = String.split(headers["content-type"], ";")

    if contype_forbidden(content_type) do
      {:halt, content_type}
    else
      {:cont, content_type}
    end
  end

  defp handle_response_chunk(%AsyncHeaders{headers: headers}, opts) do
    headers =
      headers |> extract_headers(["content-type", "content-length", "content-disposition"])

    with {:halt, content_type} <- check_content_type(headers) do
      finish_download({:error, {:unexpected_content_type, content_type}}, opts)
    else
      {:cont, _} ->
        with content_length <- headers["content-length"],
             true <- is_binary(content_length) do
          Logger.debug("got content_length : #{content_length}")

          try do
            send(
              opts.download_pid,
              {:update_progress, {:content_length, String.to_integer(content_length)}}
            )
          rescue
            ArgumentError -> nil
          end
        end

        with cont_dis <- headers["content-disposition"],
             true <- is_binary(cont_dis),
             %{"filename" => filename} <-
               Regex.named_captures(
                 ~r/filename=['"]?(?<filename>[^'";]+)['"]?/i,
                 cont_dis
               ) do
          Logger.debug("got filename : #{filename}")

          send(
            opts.download_pid,
            {:update_progress, {:set_filename, filename}}
          )
        end

        do_download(opts)

      _ ->
        finish_download({:error, :unknown}, opts)
    end
  end

  defp extract_headers(headers, keys \\ []) do
    headers
    |> Enum.reduce(
      %{},
      fn header = {header_name, value}, acc ->
        clean_name = String.downcase(header_name)

        if Enum.member?(keys, clean_name) do
          acc |> Map.put(clean_name, value)
        else
          acc
        end
      end
    )
  end

  defp contype_forbidden(content_type) when is_binary(content_type) do
    String.match?(content_type, ~r/text\/html/i)
  end

  defp handle_response_chunk(%AsyncChunk{chunk: data}, opts) do
    IO.binwrite(opts.file, data)

    send(opts.download_pid, {:update_progress, {:downloaded_bytes, byte_size(data)}})

    do_download(opts)
  end

  defp handle_response_chunk(%AsyncEnd{}, opts), do: finish_download({:ok}, opts)

  defp finish_download(state, opts) do
    Logger.debug("finish download with opts : #{inspect(opts)}")
    File.close(opts.file)

    case state do
      {:ok} ->
        send(opts.download_pid, {:update_status, :finished})

      {:error, reason} ->
        File.rm!(opts.path)

        send(
          opts.download_pid,
          {:update_status, {:errored, reason}}
        )

      {:error} ->
        File.rm!(opts.path)

        send(
          opts.download_pid,
          {:update_status, {:errored, :unknown}}
        )

      _ ->
        File.rm!(opts.path)

        send(
          opts.download_pid,
          {:update_status, {:crashed, :unknown}}
        )
    end
  end
end
