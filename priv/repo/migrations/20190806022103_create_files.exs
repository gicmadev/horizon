defmodule Horizon.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :filename, :string
      add :sha256, :string

      timestamps()
    end

  end
end
