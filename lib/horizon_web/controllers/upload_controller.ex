defmodule HorizonWeb.UploadController do
  use HorizonWeb, :controller

  require Logger

  def upload(conn, %{"file" => file}) do
    disable_timeout(conn)

    {:ok, ash_id} = Horizon.StorageManager.store!(file)

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(200, Poison.encode!(%{ok: true, ash_id: ash_id}, pretty: true))
  end

  def status(conn, %{"ash_id" => ash_id}) do
    disable_timeout(conn)
    check_token(conn)

    status = Horizon.StorageManager.status(ash_id)

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json; charset=utf-8")
    |> Plug.Conn.send_resp(200, Poison.encode!(%{ok: true, status: status}, pretty: true))
  end

  defp check_token(conn) do
    token = case extract_token(conn) do
      {:ok, token} -> verify_token(token)
      error -> error
    end

    Logger.debug("token : #{inspect token}")
  end

  defp verify_token(token) do
    keys = Application.get_env(:horizon, Horizon.SecureTokens)
    Logger.debug("config : #{inspect keys}")

    {:ok, claims} = token |> Joken.peek_claims
    issuer = String.to_atom(claims["iss"])

    Logger.debug("issuers : #{inspect issuer}")

    if Keyword.has_key?(keys, issuer) do
      pem_data = keys[issuer]

      Logger.debug("pem data : #{inspect pem_data}")

      Joken.verify_and_validate(Joken.Config.default_claims(iss: claims["iss"]), token, %Joken.Signer{
        alg: "RS256",
        jwk: JOSE.JWK.from_pem(pem_data[:key]),
        jws: JOSE.JWS.generate_key(%{"alg" => "RS256"})
      })
    else
      {:error, "unknown issuer"}
    end
  end

  defp extract_token(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      [auth_header] -> get_token_from_header(auth_header)
       _ -> {:error, :missing_auth_header}
    end
  end

  defp get_token_from_header(auth_header) do
    {:ok, reg} = Regex.compile("Bearer\:?\s+(.*)$", "i")
    case Regex.run(reg, auth_header) do
      [_, match] -> {:ok, String.trim(match)}
      _ -> {:error, "token not found"}
    end
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
