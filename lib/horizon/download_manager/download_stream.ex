defmodule Horizon.DownloadManager.DownloadStream do
  @enforce_keys [:url, :path, :full_size]
  defstruct [:url, :path, :file, :full_size]

  @chunk_size 4096
  @throttle Kernel.trunc(Float.round(750 / (512 * 1024 / @chunk_size)))

  require Logger

  def stream_download(conn, stream, offset \\ 0) do
    if offset < stream.full_size do
      current_size = stream_size(stream)

      limit = Enum.min([offset + @chunk_size, stream.full_size])

      Logger.debug("Will send stream from #{stream.path} bytes : #{offset} - #{limit}")

      if current_size < offset do
        Logger.debug("waiting 500ms")
        Process.sleep(500)
        stream_download(conn, stream, offset)
      else
        Logger.debug("Ready to send")

        Logger.debug("Reading file")

        {:ok, f} = :file.open(stream.path, [:binary])
        {:ok, data} = :file.pread(f, offset, limit - offset)
        :file.close(f)

        case Plug.Conn.chunk(conn, data) do
          {:ok, conn} ->
            Logger.debug("Sent chunk")

            if current_size < stream.full_size do
              Logger.debug("throttling #{inspect(@throttle)}")
              Process.sleep(@throttle)
              Logger.debug("throttled")
            end

            Logger.debug("Looping")
            stream_download(conn, stream, limit)

          {:error, :closed} ->
            Logger.info("Client closed connection before receiving the next chunk")
            conn

          {:error, reason} ->
            Logger.info("Unexpected error, reason: #{inspect(reason)}")
            conn

          returnVal ->
            Logger.debug("Unknown retval : #{returnVal}")
            conn
        end
      end
    else
      Logger.debug("offset is bigger than total")
      conn
    end
  end

  defp stream_size(%{path: path}) do
    {:ok, %{size: size}} = File.stat(path)
    IO.inspect(size, label: "Stream size")

    size
  end
end
