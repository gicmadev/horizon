defmodule Horizon.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    BlobStorageEnum.create_type()

    create table(:blobs) do
      add(:sha256, :string)
      add(:storage, BlobStorageEnum.type())
      add(:remote_id, :string)

      timestamps()
    end

    create(unique_index(:blobs, [:sha256, :storage]))
  end
end
