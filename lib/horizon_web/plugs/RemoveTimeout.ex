defmodule HorizonWeb.Plugs.RemoveTimeout do
  def init(options), do: options

  def call(conn, _opts) do
    {Plug.Cowboy.Conn, %{pid: pid, streamid: streamid}} = conn.adapter

    Kernel.send(
      pid,
      {
        {pid, streamid},
        {:set_options, %{idle_timeout: :infinity}}
      }
    )

    conn
  end
end
