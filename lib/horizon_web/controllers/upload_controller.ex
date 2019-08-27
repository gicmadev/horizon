defmodule HorizonWeb.UploadController do
  use HorizonWeb, :controller
  require Logger

  plug HorizonWeb.Plugs.RemoveTimeout
  plug HorizonWeb.Plugs.VerifyToken

  def upload(conn, %{"file" => file}) do
    {:ok, ash_id} = Horizon.StorageManager.store!(file)

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(200, Poison.encode!(%{ok: true, ash_id: ash_id}, pretty: true))
  end

  def status(conn, %{"ash_id" => ash_id}) do
    status = Horizon.StorageManager.status(ash_id)

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(200, Poison.encode!(%{ok: true, status: status}, pretty: true))
  end

end
