defmodule HorizonWeb.UploadController do
  use HorizonWeb, :controller
  require Logger

  plug HorizonWeb.Plugs.RemoveTimeout
  plug HorizonWeb.Plugs.VerifyToken

  def new(conn) do
    {:ok, asset} = Horizon.StorageManager.new!()

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(200, Poison.encode!(%{id: asset.id}, pretty: true))
  end

  def upload(conn, %{"asset_id" => asset_id, "file" => file}) do
    {:ok, asset} = Horizon.StorageManager.store!(asset_id, file)

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(200, Poison.encode!(%{ok: true, id: asset.id}, pretty: true))
  end

  def status(conn, %{"ash_id" => ash_id}) do
    status = Horizon.StorageManager.status(ash_id)

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(200, Poison.encode!(%{ok: true, status: status}, pretty: true))
  end
end
