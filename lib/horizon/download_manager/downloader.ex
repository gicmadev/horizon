defmodule Horizon.DownloadManager.Downloader do
  alias HTTPoison.{AsyncHeaders, AsyncRedirect, AsyncStatus, AsyncChunk, AsyncEnd}

  require Logger

  @wait_timeout 5000

  def run(req) do
    Logger.debug("Running downloader with req #{inspect(req)}")

    File.rm(req.path)

    with {:ok, file} <- File.open(req.path, [:write, :exclusive]),
         {:ok, _} <- req |> do_request do
      req
      |> Map.put(:file, file)
      |> wait_response
    else
      {:error, reason} -> req |> finish_download({:error, reason})
      err -> req |> finish_download({:crashed, err})
      _ -> req |> finish_download({:crashed, :unknown})
    end
  end

  defp do_request(%{url: url}) do
    Logger.debug("Starting GET request to #{url} with stream_to #{inspect(self())}")

    HTTPoison.get(url, %{},
      stream_to: self(),
      follow_redirect: true,
      hackney: [force_redirect: true, max_redirect: 15]
    )
  end

  defp wait_response(req) do
    receive do
      response_chunk -> req |> handle_response_chunk(response_chunk)
    after
      @wait_timeout -> req |> finish_download({:error, :timeout_failure})
    end
  end

  defp handle_response_chunk(req, %AsyncRedirect{to: to}) do
    Logger.debug("Redirecting to #{to}")

    req =
      req
      |> set_status(:redirecting)
      |> Map.put(:url, to)
      |> Map.update(:redirected, 0, &(&1 + 1))

    with {:cont} <- check_redirect_loop(req),
         {:ok, _} <- req |> do_request do
      req |> wait_response
    else
      {:error, reason} -> req |> finish_download({:error, reason})
      err -> req |> finish_download({:crash, err})
      _ -> req |> finish_download({:crash, :unknown})
    end
  end

  defp handle_response_chunk(req, %AsyncStatus{code: code}) do
    cond do
      code in [200, 206] ->
        req
        |> set_status(:downloading)
        |> wait_response

      code in [303, 308] ->
        # Manual redirect not handled by hackney
        req
        |> set_status(:redirecting)
        |> wait_response

      true ->
        req |> finish_download({:error, {:unexpected_status_code, code}})
    end
  end

  defp handle_response_chunk(req, %AsyncHeaders{headers: hdrs}) do
    headers =
      hdrs
      |> extract_headers([
        "location",
        "content-type",
        "content-length",
        "content-disposition"
      ])

    with {:cont} <- req |> should_manually_redirect(headers),
         {:cont, content_type} <- check_content_type(headers) do
      req
      |> set_status(:downloading)
      |> set_content_length(headers)
      |> set_filename_from_content_disposition(headers)
      |> set_content_type(content_type)
      |> set_missing_extension_from_content_type
      |> sync_to_download
      |> wait_response
    else
      {:redirect, loc} ->
        req |> handle_response_chunk(%AsyncRedirect{to: loc})

      {:unexpected_content_type, content_type} ->
        req |> finish_download({:error, {:unexpected_content_type, content_type}})
    end
  end

  defp handle_response_chunk(req, %AsyncChunk{chunk: data}) do
    req.file |> IO.binwrite(data)

    req
    |> send_progress(byte_size(data))
    |> wait_response
  end

  defp handle_response_chunk(req = %{status: :redirecting}, %AsyncEnd{}),
    do: req |> wait_response

  defp handle_response_chunk(req, %AsyncEnd{}),
    do: req |> finish_download({:ok})

  defp check_redirect_loop(_req = %{redirected: redirected}) when is_integer(redirected) do
    if redirected > 10 do
      {:error, :too_many_redirect}
    else
      {:cont}
    end
  end

  defp check_redirect_loop(_), do: {:cont}

  defp send_progress(req = %{download_pid: pid}, size) when is_integer(size) do
    send(pid, {:update_progress, {:downloaded_bytes, size}})

    req
  end

  defp extract_headers(headers, keys) do
    headers
    |> Enum.reduce(
      %{},
      fn {header_name, value}, acc ->
        clean_name = String.downcase(header_name)

        if Enum.member?(keys, clean_name) do
          acc |> Map.put(clean_name, value)
        else
          acc
        end
      end
    )
  end

  defp should_manually_redirect(
         _req = %{status: :redirecting, url: url},
         _headers = %{"location" => loc}
       )
       when is_binary(loc) do
    with loc <- String.trim(loc),
         true <- String.length(loc) > 0,
         false <- String.equivalent?(loc, url) do
      {:redirect, loc}
    else
      _ -> {:cont}
    end
  end

  defp should_manually_redirect(_req, _headers) do
    {:cont}
  end

  defp set_content_type(req, content_type) when is_binary(content_type) do
    req |> Map.put(:content_type, content_type)
  end

  defp set_content_type(req, _cont_type), do: req

  defp set_content_length(req, %{"content-length" => content_length})
       when is_binary(content_length) do
    Logger.debug("got content_length : #{content_length}")

    try do
      req |> Map.put(:content_length, String.to_integer(content_length))
    rescue
      ArgumentError -> req
    end
  end

  defp set_content_length(req, _), do: req

  defp set_filename_from_content_disposition(req, %{"content-disposition" => cont_dis})
       when is_binary(cont_dis) do
    captured =
      Regex.named_captures(
        ~r/filename=['"]?(?<filename>[^'";]+)['"]?/i,
        cont_dis
      )

    case captured do
      %{"filename" => filename} ->
        Logger.debug("got filename : #{filename}")

        req |> Map.put(:filename, filename)

      _ ->
        req
    end
  end

  defp set_filename_from_content_disposition(req, _), do: req

  defp set_missing_extension_from_content_type(
         req = %{filename: filename, content_type: content_type}
       ) do
    with true <- is_binary(filename),
         true <- is_binary(content_type),
         ext <- Path.extname(filename),
         true <- ext in [".", ""],
         [ext | _] <-
           MIME.extensions(content_type) do
      req |> Map.put(:filename, filename <> "." <> ext)
    else
      _ -> req
    end
  end

  defp check_content_type(%{"content-type" => cont_type}) when is_binary(cont_type) do
    [content_type | _] = String.split(cont_type, ";")

    if contype_forbidden(content_type) do
      {:unexpected_content_type, content_type}
    else
      {:cont, content_type}
    end
  end

  defp check_content_type(_), do: {:cont, "application/octet-stream"}

  defp contype_forbidden(content_type) when is_binary(content_type) do
    String.match?(content_type, ~r/text\/html/i)
  end

  defp finish_download(req, state) do
    Logger.debug("finish download with req : #{inspect(req)}")

    if req.file, do: File.close(req.file)
    unless state == {:ok}, do: File.rm!(req.path)

    status =
      case state do
        {:ok} -> :finished
        {:error, reason} -> {:errored, reason}
        {:error} -> {:errored, :unknown}
        {:crash, reason} -> {:crashed, reason}
        _ -> {:crashed, :unknown}
      end

    req
    |> set_status(status)
    |> sync_to_download
  end

  defp set_status(req, status) do
    req |> Map.put(:status, status)
  end

  defp is_present_string(str) when is_binary(str), do: byte_size(str |> String.trim()) > 0
  defp is_present_string(_), do: false

  defp sync_to_download(req) do
    with filename <- Map.get(req, :filename),
         true <- is_present_string(filename) do
      send(
        req.download_pid,
        {:update_progress, {:set_filename, filename}}
      )
    end

    with content_length <- Map.get(req, :content_length),
         true <- is_integer(content_length),
         true <- content_length >= 0 do
      send(
        req.download_pid,
        {:update_progress, {:set_content_length, content_length}}
      )
    end

    send(
      req.download_pid,
      {:update_status, req.status}
    )

    req
  end
end
