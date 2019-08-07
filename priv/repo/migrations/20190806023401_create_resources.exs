defmodule Horizon.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    ResourcesStorageEnum.create_type()

    create table(:resources) do
      add(:sha256, :string)
      add(:storage, ResourcesStorageEnum.type())
      add(:remote_id, :string)

      timestamps()
    end
  end
end
