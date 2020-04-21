defmodule Horizon.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";")

    UploadStatusEnum.create_type()

    # Run as admin in db :
    #
    # CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

    create table(:uploads, primary_key: false) do
      add(:id, :uuid,
        primary_key: true,
        default:
          fragment("uuid_generate_v5(uuid_generate_v4(), '#{System.get_env("UUID_V5_SECRET")}')"),
        read_after_writes: true
      )

      add(:filename, :string)
      add(:sha256, :string)

      add(:content_type, :string)
      add(:content_length, :bigint)

      add(:duration, :integer)
      add(:artwork, :binary)

      add(:source, :string)
      add(:bucket, :string)
      add(:owner, :string)

      add(:status, UploadStatusEnum.type())

      timestamps()
    end

    create(unique_index(:uploads, :source))
    create(index(:uploads, :bucket))
    create(index(:uploads, :owner))
  end
end
