defmodule HorizonWeb.Plugs.VerifyToken do
  alias Plug.Conn

  require Logger

  def init(options), do: options

  def call(conn, _opts) do
    conn |> check_token
  end

  defp check_token(conn) do
    with {:ok, token} <- extract_token(conn),
         {:ok, claims} <- claims_for_conn(conn),
         {:ok, token} <- verify_token(token, claims) do
      conn
      |> Conn.assign(:token, token)
    else
      err -> forbidden(conn, err)
    end
  end

  defp forbidden(conn, reason) do
    Logger.warn("Forbidden! Error verifying auth token. #{inspect(reason)}")

    conn
    |> Conn.send_resp(:unauthorized, "")
    |> Conn.halt()
  end

  defp claims_for_conn(conn) do
    claims = %{}

    ash_id =
      if Phoenix.Controller.action_name(conn) === :new do
        Map.get(conn.params, "source")
      else
        Map.get(conn.params, "upload_id")
      end

    claims =
      if ash_id do
        Map.put(claims, "sub", ash_id)
      else
        claims
      end

    {:ok, claims}
  end

  defp verify_token(token, claims) do
    keys = Application.get_env(:horizon, Horizon.SecureTokens)

    {:ok, token_claims} = token |> Joken.peek_claims()
    token_issuer = token_claims["iss"]

    iss_key = String.to_atom(token_issuer)

    if Keyword.has_key?(keys, iss_key) do
      pem_data = keys[iss_key]

      token_config = make_token_config(Map.merge(%{"iss" => token_issuer}, claims))

      Joken.verify_and_validate(token_config, token, %Joken.Signer{
        alg: "RS256",
        jwk: JOSE.JWK.from_pem(pem_data[:key]),
        jws: JOSE.JWS.generate_key(%{"alg" => "RS256"})
      })
    else
      {:error, "unknown issuer"}
    end
  end

  defp make_token_config(claims) do
    config = Joken.Config.default_claims(iss: claims["iss"])

    config =
      Enum.reduce(
        claims,
        config,
        fn {key, value}, config ->
          config |> Joken.Config.add_claim(key, nil, &(&1 == value))
        end
      )

    config
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
end
