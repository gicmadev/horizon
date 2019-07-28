defmodule HorizonWeb.DownloadController do
  use HorizonWeb, :controller

  alias Horizon.DownloadManager
  alias Horizon.DownloadManager.DownloadStream

  def download(conn, _params) do
    file = %{
      url: "https://podshows.download/p2p/video/P2P37.mp4",
      content_type: "video/mp4",
      content_length: 491_768_935
    }

    conn =
      conn
      |> put_resp_content_type(file.content_type)
      |> put_resp_header("content-length", Integer.to_string(file.content_length))

    disable_timeout(conn)

    case DownloadManager.ensure_downloaded(file.url, file.content_length) do
      {:downloaded, path} ->
        send_file_from_path(conn, path)

      {:downloading, download_stream} ->
        send_file_from_download_stream(conn, download_stream)
    end
  end

  defp disable_timeout(conn) do
    {Plug.Cowboy.Conn, %{pid: pid, streamid: streamid}} = conn.adapter

    Kernel.send(
      pid,
      {
        {pid, streamid},
        {:set_options, %{idle_timeout: :infinity}}
      }
    )
  end

  defp send_file_from_path(conn, file_path) do
    offset = get_offset(conn.req_headers)

    %{size: file_size} = File.stat!(file_path)

    conn
    |> put_resp_header(
      "content-range",
      "bytes #{offset}-#{file_size - 1}/#{file_size}"
    )
    |> send_file(206, file_path, offset, file_size - offset)
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

      nil ->
        0
    end
  end
end
