defmodule HorizonWeb.UploadController do
  use HorizonWeb, :controller

  def upload(conn, %{"file" => file}) do
    disable_timeout(conn)

    {:ok, asset} = Horizon.StorageManager.store!(file)

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(200, Poison.encode!(%{ok: true, asset: asset}, pretty: true))
  end

  defp disable_timeout(conn) do
    {Plug.Cowboy.Conn, %{pid: pid, streamid: streamid}} = conn.adapter

    Kernel.send(
      pid,
      {
        {pid, streamid},
        {:set_options, %{idle_timeout: :infinity}}
      }
    )
  end
end
