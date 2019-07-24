defmodule HorizonWeb.DownloadController do
  use HorizonWeb, :controller

  def download(conn, _params) do
    url = "https://podshows.download/p2p/video/P2P36.mp4"

    %{headers: proxy_headers} = HTTPoison.head!(url)
    proxy_headers = for {k, v} <- proxy_headers, do: {String.downcase(k), v}, into: %{}

    chunked_conn =
      conn
      |> put_resp_content_type(proxy_headers["content-type"])
      |> put_resp_header("content-length", proxy_headers["content-length"])
      |> send_chunked(200)

    {:ok, file} = :file.open("/tmp/data.mp4", [:write, :raw])

    url
    |> RemoteFileStreamer.stream()
    |> Stream.map(fn n ->
      :file.write(file, n)
      chunk(chunked_conn, n)
    end)
    |> Stream.run()
  end
end
