# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :horizon,
  ecto_repos: [Horizon.Repo]

# Configures the endpoint
config :horizon, HorizonWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "iHQ8Ph3E8lUDx0Q0OrOLryh7xjbjEtE2XLUJeqJ0eBfFHbiFQUuLBOX6btHQY9RC",
  render_errors: [view: HorizonWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Horizon.PubSub, adapter: Phoenix.PubSub.PG2]

config :horizon, Horizon.DownloadManager, dl_path: "/tmp/remote_download"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# List here all of your upload controllers
config :tus, controllers: [HorizonWeb.UploadChunksController]

# This is the config for the HorizonWeb.UploadController
config :tus, HorizonWeb.UploadChunksController,
  storage: Tus.Storage.Local,
  base_path: "/tmp/tus_uploads",
  cache: Tus.Cache.Memory,
  max_size: 10 * 1024 * 1024 * 1024

config :ex_aws, :s3,
  scheme: "https://",
  host: "s3.eu-central-1.wasabisys.com",
  debug_requests: true,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: ""

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
