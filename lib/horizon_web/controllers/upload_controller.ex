defmodule HorizonWeb.UploadController do
  use HorizonWeb, :controller

  alias Horizon.Repo
  alias Horizon.Schema.File, as: FileModel
  alias Horizon.Schema.Resource

  def upload(conn, %{"file" => file}) do
    disable_timeout(conn)

    sha256 = get_sha256(file.path)

    Repo.transaction(fn ->
      Repo.insert!(
        FileModel.changeset(%FileModel{}, %{
          filename: file.filename,
          sha256: sha256
        })
      )

      res = Repo.get_by(Resource, sha256: sha256, storage: :horizon)
      if res === nil do
        horizon_path = "/downloads/" <> sha256
        File.cp!(file.path, horizon_path)
        Repo.insert!(
          Resource.changeset(%Resource{}, %{
            sha256: sha256, 
            storage: :horizon,
            remote_id: horizon_path
          })
        )
      end
    end)

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(200, Poison.encode!(%{ok: true}, pretty: true))
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

  defp get_sha256(file_path) do
    File.stream!(file_path,[],2_048)
    |> Enum.reduce(:crypto.hash_init(:sha256), &(:crypto.hash_update(&2, &1)))
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end
end
