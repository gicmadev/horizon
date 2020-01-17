defmodule HorizonWeb.StorageController do
  use HorizonWeb, :controller

  plug(HorizonWeb.Plugs.VerifyToken)

  def status(conn, %{"owner" => owner}) do
    {:ok, status} = Horizon.StorageManager.storage_status(owner)

    json_resp = status |> Map.merge(%{ok: true}) |> Poison.encode!(pretty: true)

    conn
      |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
      |> Plug.Conn.send_resp(200, json_resp)
  end

  def status(conn, %{}) do
    {:ok, status} = Horizon.StorageManager.storage_status

    json_resp = status |> Map.merge(%{ok: true}) |> Poison.encode!(pretty: true)

    conn
      |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
      |> Plug.Conn.send_resp(200, json_resp)
  end

end
