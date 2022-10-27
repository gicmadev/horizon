defmodule Horizon.StorageManager.Provider.Wasabi.Uploader do
  @moduledoc "Upload file to S3 compatible storage"

  require Logger

  alias ExAws.S3

  def start(file_path, sha256, bucket, remote_path, provider_pid) do
    Logger.info("Starting upload of #{inspect(file_path)}")
    Logger.info("bucket : #{inspect(bucket)}")
    Logger.info("remote path : #{inspect(remote_path)}")

    result =
      file_path
      |> S3.Upload.stream_file()
      |> S3.upload(bucket, remote_path)
      # => :done
      |> ExAws.request!()

    case result do
      %{status_code: 200} ->
        send(provider_pid, {:uploaded, sha256})

        Logger.info("Finished upload of #{inspect(file_path)}")

      _ ->
        Logger.error(
          "An error occured during upload of #{inspect(file_path)} : #{inspect(result)}"
        )
    end
  end
end
