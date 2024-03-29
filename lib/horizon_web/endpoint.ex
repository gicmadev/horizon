defmodule HorizonWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :horizon

  #  socket "/socket", HorizonWeb.UserSocket,
  #   websocket: true,
  #  longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :horizon,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, {:multipart, length: 20_000_000_000}, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(Plug.Session,
    store: :cookie,
    key: "_horizon_key",
    signing_salt: "ctg3Xeo1"
  )

  plug(Corsica,
    origins: Application.get_env(:horizon, HorizonWeb.Endpoint)[:api_origins],
    log: [rejected: :error],
    allow_headers:
      ~w(authorization content-disposition tus-resumable upload-length upload-metadata location content-type upload-offset),
    expose_headers:
      ~w(content-disposition content-length tus-resumable upload-length upload-metadata location content-type upload-offset)
  )

  plug(HorizonWeb.Router)
end
