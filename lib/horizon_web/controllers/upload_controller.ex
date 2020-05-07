defmodule HorizonWeb.UploadController do
  use HorizonWeb, :controller
  require Logger

  plug(HorizonWeb.Plugs.RemoveTimeout)
  plug(HorizonWeb.Plugs.VerifyToken)

  def new(conn, params) do
    upload =
      case Horizon.StorageManager.upload_for_source(params["source"]) do
        nil ->
          {:ok, upload} = Horizon.StorageManager.new!(params)
          upload

        upload ->
          upload
      end

    conn |> send_ok_data(%{id: upload.id, status: upload.status})
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

  def get(conn, params = %{"upload_id" => upload_id}) do
    Logger.debug("upload_id : #{upload_id}")

    {:ok, upload} = Horizon.StorageManager.get!(upload_id)

    data = %{
      status: upload.status,
      name: upload.filename,
      size: upload.content_length,
      type: upload.content_type,
      duration: upload.duration,
      artwork: upload.artwork
    }

    data =
      with true <- is_binary(upload.downloading_url),
           true <- String.length(upload.downloading_url) > 0 do
        data |> Map.put(:downloading_url, upload.downloading_url)
      else
        _ -> data
      end

    data =
      try do
        with true <- upload.status == :downloading,
             {status, _, progress} <- Horizon.DownloadManager.get_status(upload.downloading_url) do
          data
          |> Map.put(:progress, progress)
          |> Map.put(:downloading_status, status)
        else
          _ -> data
        end
      catch
        :exit, value ->
          IO.inspect({:caught_an_exit, value})
          data
      end

    data =
      with true <- upload.status == :downloading_failed,
           {:ok, err_data} <- Jason.decode(upload.downloading_error) do
        data |> Map.put(:downloading_error, err_data)
      else
        _ -> data
      end

    Logger.debug("params: #{inspect(params)}")

    drop_keys =
      params
      |> Map.get("without", "")
      |> String.split(",")
      |> Enum.map(&String.to_atom/1)

    data = data |> Map.drop(drop_keys)

    data =
      data
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        with false <- Enum.member?(drop_keys, key),
             false <- is_nil(value) do
          acc |> Map.put(key, value)
        else
          _ -> acc
        end
      end)

    conn |> send_ok_data(data)
  end

  def burn(conn, %{"upload_id" => upload_id}) do
    Logger.debug("upload_id : #{upload_id}")

    {:ok, :burnt} = Horizon.StorageManager.burn!(upload_id)

    conn |> send_ok_data(%{burnt: true})
  end

  def download(conn, params = %{"upload_id" => upload_id, "url" => url}) do
    with {:is_new, true} <- {:is_new, Horizon.StorageManager.is_new?(upload_id)},
         {:store_remote, {:ok, {:started, _, _}}} <-
           {:store_remote, Horizon.StorageManager.store_remote!(upload_id, url)} do
      conn
      |> put_status(201)
      |> send_ok_data()
    else
      {:store_remote, {:error, {:not_found, _, _}}} ->
        conn |> send_error_data("error starting download")

      {:store_remote, {:error, {:downloading, _, _}}} ->
        conn |> put_status(201) |> send_ok_data()

      {:is_new, false} ->
        conn |> put_status(201) |> send_ok_data()

      err ->
        Logger.error(inspect(err))
        conn |> send_error_data("unknown error")
    end
  end

  defp redirect_to_upload(conn, params = %{"upload_id" => upload_id}) do
    conn
    |> put_status(303)
    |> redirect(
      to:
        Routes.upload_path(
          conn,
          :get,
          upload_id,
          without: params |> Map.get("without", "artwork")
        )
    )
  end

  defp send_ok_data(conn, data \\ %{}, status \\ 200) do
    conn |> send_json(Map.merge(%{ok: true}, data), status)
  end

  defp send_error_data(conn, message) when is_binary(message) do
    conn |> send_error_data(%{message: message})
  end

  defp send_error_data(conn, data, status \\ 500) when is_map(data) do
    conn |> send_json(Map.merge(%{error: true}, data), status)
  end

  defp send_json(conn, data, status) do
    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(status, Poison.encode!(data, pretty: true))
  end
end
