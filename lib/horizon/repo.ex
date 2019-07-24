defmodule Horizon.Repo do
  use Ecto.Repo,
    otp_app: :horizon,
    adapter: Ecto.Adapters.Postgres
end
