defmodule Horizon.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    AssetStatusEnum.create_type()

    create table(:assets) do
      add :filename, :string
      add :sha256, :string
      add :content_type, :string
      add(:status, AssetStatusEnum.type())

      timestamps()
    end

  end
end
