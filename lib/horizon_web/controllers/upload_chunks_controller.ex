defmodule HorizonWeb.UploadChunksController do
  use HorizonWeb, :controller
  use Tus.Controller

  require Logger

  plug(HorizonWeb.Plugs.RemoveTimeout)
  plug(HorizonWeb.Plugs.VerifyToken)

  # start upload optional callback
  def on_begin_upload(file) do
    :ok  # or {:error, reason} to reject the uplaod
  end

  # Completed upload optional callback
  def on_complete_upload(file) do
    Horizon.StorageManager.store!(
      get_file_metadata(file, "upload_id"), 
      %{
        path: Path.join(
          Application.get_env(:tus, HorizonWeb.UploadChunksController)[:base_path],
          file.path
        ),
        filename: get_file_metadata(file, "filename")
      }
    )
  end

  defp get_file_metadata(file, key) do
    file.metadata |> List.keyfind(key, 0) |> elem(1)
  end
end
