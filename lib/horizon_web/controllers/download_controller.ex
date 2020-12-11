defmodule HorizonWeb.DownloadController do
  use HorizonWeb, :controller

  alias Horizon.StorageManager
  alias Horizon.DownloadManager.DownloadStream

  import Logger

  plug(HorizonWeb.Plugs.RemoveTimeout)

  def download(conn, params) do
    %{"upload_id" => upload_id} = params
    upload_id = upload_id |> String.split(".") |> Enum.at(0)

    case Horizon.StorageManager.download!(upload_id) do
      {:downloaded, file_path, size, content_type} ->
        send_file_from_path(conn, file_path, size, content_type)

      {:downloading, download_stream, size, content_type} ->
        send_file_from_download_stream(conn, download_stream, size, content_type)

      nil -> conn |> send_resp(404, "File not found")
    end
  end

  defp send_file_from_path(conn, file_path, file_size, content_type) do
    conn =    conn
        |> put_resp_header(
          "Content-Type",
          content_type
        )
        |> put_resp_header(
          "cache-control",
          "max-age=3600"
        )

    case get_ranges(conn.req_headers, file_size) do
      nil ->
        conn
        |> put_resp_header(
          "Accept-Ranges",
          "bytes"
        )
        |> send_file(200, file_path)
        |> halt

      [ {offset, size} | _ ] ->
        conn
        |> put_resp_header(
          "content-range",
          "bytes #{offset}-#{offset+size-1}/#{file_size}"
        )
        |> send_file(206, file_path, offset, size)
        |> halt
    end
  end

  def send_file_from_download_stream(conn, download_stream, file_size, content_type) do
    case get_ranges(conn.req_headers, file_size) do
      nil ->
        conn
        |> put_resp_header(
          "Accept-Ranges",
          "bytes"
        )
        |> DownloadStream.stream_download(download_stream, 0)
        |> halt

      [ {offset, size} | _ ] ->
        conn
        |> put_resp_header(
          "content-range",
          "bytes #{offset}-#{offset+size-1}/#{file_size}"
        )
        |> send_chunked(206)
        |> DownloadStream.stream_download(download_stream, offset)
        |> halt
    end
  end

  defp get_ranges(headers, fullsize) do
    case List.keyfind(headers, "range", 0) do
      {"range", range} ->
        ["bytes" | ranges ] = range |> String.downcase |> String.split("=")

        ranges = ranges 
                 |> Enum.at(0)
                 |> String.split(",") 
                 |> Enum.map(&parse_range/1)
                 |> Enum.reject(fn x -> x == nil end)
                 |> Enum.map(fn {offset, endset} ->
                   case {offset, endset} do
                     {nil, endset} -> {fullsize - endset, endset}
                     {offset, nil} -> {offset, fullsize - offset}
                     {offset, endset} -> {offset, endset + 1 - offset}
                   end
                 end)

        if Enum.count(ranges) == 0 do
          nil
        else
          ranges
        end

      nil -> nil
    end
  end

  defp parse_range(rng) do
    sets =  Regex.named_captures(~r/^(?<start>[\d]*)-(?<end>[\d]*)$/, rng)

    if sets == nil do
      nil
    else
      %{"start" => offset, "end" => endset} = sets

      offset = case offset do
        "" -> nil
        val -> String.to_integer(val)
      end
      
      endset = case endset do
        "" -> nil
        val -> String.to_integer(val)
      end

      {offset, endset}
      
    end
  end


end
