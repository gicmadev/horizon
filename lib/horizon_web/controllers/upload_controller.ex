defmodule HorizonWeb.UploadController do
  use HorizonWeb, :controller
  require Logger

  plug HorizonWeb.Plugs.RemoveTimeout
  plug HorizonWeb.Plugs.VerifyToken

  def new(conn, _params) do
    {:ok, upload} = Horizon.StorageManager.new!()

    conn |> send_ok_data(%{id: upload.id})
  end

  def ensure(conn, %{"upload_id" => upload_id}) do
    case Horizon.StorageManager.get!(upload_id) do
      {:ok, upload} -> conn |> send_ok_data(%{id: upload.id})
      nil -> conn |> send_ko_data(%{id: upload_id}, 404)
    end
  end

  def upload(conn, %{"upload_id" => upload_id, "file" => file}) do
    {:ok, upload} = Horizon.StorageManager.store!(upload_id, file)

    conn |> send_ok_data(%{id: upload.id})
  end

  def status(conn, %{"ash_id" => ash_id}) do
    status = Horizon.StorageManager.status(ash_id)

    conn |> send_ok_data(%{status: status})
  end

  defp send_ko_data(conn, data, status \\ 200) do
    conn |> send_json(Map.merge(%{ok: false}, data), status)
  end

  defp send_ok_data(conn, data, status \\ 200) do
    conn |> send_json(Map.merge(%{ok: true}, data), status)
  end

  def send_json(conn, data, status \\ 200) do
    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(status, Poison.encode!(data, pretty: true))
  end
end
