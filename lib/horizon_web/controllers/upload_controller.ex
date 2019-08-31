defmodule HorizonWeb.UploadController do
  use HorizonWeb, :controller
  require Logger

  plug HorizonWeb.Plugs.RemoveTimeout
  plug HorizonWeb.Plugs.VerifyToken

  def new(conn, _params) do
    {:ok, asset} = Horizon.StorageManager.new!()

    conn |> send_ok_data(%{id: asset.id})
  end

  def ensure(conn, %{"asset_id" => asset_id}) do
    case Horizon.StorageManager.get!(asset_id) do
      {:ok, asset} -> conn |> send_ok_data(%{id: asset.id})
      nil -> conn |> send_ko_data(%{id: asset_id}, 404)
    end
  end

  def upload(conn, %{"asset_id" => asset_id, "file" => file}) do
    {:ok, asset} = Horizon.StorageManager.store!(asset_id, file)

    conn |> send_ok_data(%{id: asset.id})
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
