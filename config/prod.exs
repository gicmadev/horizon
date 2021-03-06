use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :horizon, HorizonWeb.Endpoint,
  http: [
    :inet6, 
    port: System.get_env("PORT") || 4000,
    protocol_options: [
        idle_timeout: 2_000
    ]
  ],
  api_origins: [~r{^https?://(.*\.?)podcloud\.fr$}]

# Do not print debug messages in production
config :logger, level: :debug

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :horizon, HorizonWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [
#         :inet6,
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your endpoint, ensuring
# no data is ever sent via http, always redirecting to https:
#
#     config :horizon, HorizonWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases (distillery)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
config :phoenix, :serve_endpoints, true

# public keys
config :horizon, Horizon.SecureTokens,
  podcloud: %{
    key: """
    -----BEGIN PUBLIC KEY-----
    MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA2ObhfH2iz/SnGkRkR4Bu
    RVavq5szv/zVYnUVHiS0lo6wPgiNQETqurjUmw37b6tMU9KjzcTOC5gS80QgKKPv
    eCms0xuLwNGeaLM5aUTLQ4xueJCzrHhUxwb7oc1+yrZRz2uYkgog5vVvPpeKwpkK
    U2rN4APxaQ/flzaqedJW3ushqqYewA6+DPH6M6OgzmL3J/I6Dj4/kGrMJTZpOKxh
    ba9UmtvL8Sc/2c2ESa+scdrU0DLPnU8yLbPpaWNkO7DC7hpmr4I+rKdcMRLWLcyn
    WnqHlUfM+/b+ZvQqWy6OFVhfVKr0E/Ktv1AMHzp5hYGEQg7uz7zdI7/U21QIDXfP
    6266tve5ZxZTScWlrSx6mhvmRQWIIT5pgWvrsQRu2zo65aNGVCoRf3NGh6QcWL0W
    bZYSrFe5NkSSfpM7XxP8cX3kvfwRvsDp+OEYcmQ/tQyEyU/eMOk1E+GPxsbLnPse
    cbGQIzp70FBMSHd+sivU4Rh8U6kD3j9C0krVQSRHnUY9SvpHBmsxXKV1R3nyzt/S
    bHt8RbKMgxnGti1ziBotGts+i5s90BQE27R9/bFtAr4Ir9qCLemzABuF6fRHQmCk
    seKEQK3cFluHTGmBFa/mEf3yJnuMXDz07aUHu9h9uvwecTZG7NLHOms5focTIGqc
    SMDrxc9sUVCBKgzIFlsnshMCAwEAAQ==
    -----END PUBLIC KEY-----
    """
  }

config :ex_aws, :s3, bucket: "horizon-prod"

# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :horizon, HorizonWeb.Endpoint, server: true
#
# Note you can't rely on `System.get_env/1` when using releases.
# See the releases documentation accordingly.

# Finally import the config/prod.secret.exs which should be versioned
# separately.
import_config "prod.secret.exs"
