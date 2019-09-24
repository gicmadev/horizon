defmodule HorizonWeb.DownloadController do
  use HorizonWeb, :controller

  alias Horizon.StorageManager
  alias Horizon.DownloadManager.DownloadStream

  import Logger

  plug(HorizonWeb.Plugs.RemoveTimeout)

  def download(conn, params) do
    %{"upload_id" => upload_id} = params
    case Horizon.StorageManager.download!(upload_id) do
      {:downloaded, file_path} ->
        send_file_from_path(conn, file_path)

      {:downloading, download_stream} ->
        send_file_from_download_stream(conn, download_stream)

      nil -> conn |> send_resp(404, "File not found")
    end
  end

  defp send_file_from_path(conn, file_path) do
    %{size: file_size} = File.stat!(file_path)

    case get_offset(conn.req_headers) do
      nil ->
        conn
        |> put_resp_header(
          "Accept-Ranges",
          "bytes"
        )
        |> send_file(200, file_path)

      offset ->
        conn
        |> put_resp_header(
          "content-range",
          "bytes #{offset}-#{file_size - 1}/#{file_size}"
        )
        |> send_file(206, file_path, offset, file_size - offset)
    end
  end

  def send_file_from_download_stream(conn, download_stream) do
    offset = get_offset(conn.req_headers)

    conn
    |> put_resp_header(
      "content-range",
      "bytes #{offset}-#{download_stream.full_size - 1}/#{download_stream.full_size}"
    )
    |> send_chunked(206)
    |> DownloadStream.stream_download(download_stream, offset)
  end

  defp get_offset(headers) do
    case List.keyfind(headers, "range", 0) do
      {"range", "bytes=" <> start_pos} ->
        String.split(start_pos, "-") |> hd |> String.to_integer()

      nil -> nil
    end
  end
end
