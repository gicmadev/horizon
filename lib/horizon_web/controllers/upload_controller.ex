defmodule HorizonWeb.UploadController do
  use HorizonWeb, :controller
  require Logger

  plug HorizonWeb.Plugs.RemoveTimeout
  plug HorizonWeb.Plugs.VerifyToken

  def new(conn, params) do
    upload =
      case Horizon.StorageManager.upload_for_source(params["source"]) do
        nil ->
          {:ok, upload} = Horizon.StorageManager.new!(params)
          upload

        upload ->
          upload
      end

    conn |> send_ok_data(%{id: upload.id})
  end

  def upload(conn, %{"upload_id" => upload_id, "horizon_file_upload" => file}) do
    Logger.debug("upload_id : #{upload_id}")

    {:ok, upload} = Horizon.StorageManager.store!(upload_id, file)

    conn |> send_ok_data(%{id: upload.id})
  end

  def revert(conn, %{"upload_id" => upload_id}) do
    Logger.debug("upload_id : #{upload_id}")

    {:ok, :reverted} = Horizon.StorageManager.revert!(upload_id)

    conn |> send_ok_data(%{reverted: true})
  end

  def delete(conn, %{"upload_id" => upload_id}) do
    Logger.debug("upload_id : #{upload_id}")

    {:ok, :deleted} = Horizon.StorageManager.remove!(upload_id)

    conn |> send_ok_data(%{deleted: true})
  end

  def get(conn, %{"upload_id" => upload_id}) do
    Logger.debug("upload_id : #{upload_id}")

    {:ok, upload} = Horizon.StorageManager.get!(upload_id)

    conn
    |> put_resp_content_type(upload.content_type, nil)
    |> put_resp_header("content-disposition", ~s[attachment; filename="#{
      upload.filename |> String.replace(~s("), ~s(\"))
    }"])
    |> put_resp_header("content-length", Integer.to_string(upload.content_length))
    |> send_upload(upload)
  end

  defp send_upload(conn, upload) do
  case Horizon.StorageManager.download!(upload.id) do
    {:downloaded, file_path} -> conn |> Plug.Conn.send_file(200, file_path)
  end
end

  def status(conn, %{"ash_id" => ash_id}) do
    status = Horizon.StorageManager.status(ash_id)

    conn |> send_ok_data(%{status: status})
  end

  defp send_ok_data(conn, data \\ %{}, status \\ 200) do
    conn |> send_json(Map.merge(%{ok: true}, data), status)
  end

  def send_json(conn, data, status \\ 200) do
    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(status, Poison.encode!(data, pretty: true))
  end
end
