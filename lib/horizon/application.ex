defmodule Horizon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Horizon.Repo,
      # Start the endpoint when the application starts
      HorizonWeb.Endpoint,
      # Starts a worker by calling: Horizon.Worker.start_link(arg)
      # {Horizon.Worker, arg},
      Horizon.DownloadManager,
      Horizon.StorageManager,
      Horizon.StorageManager.Provider.Wasabi.UploadManager,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Horizon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HorizonWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
