defmodule Horizon.Repo.Migrations.AddDownloadingStatusesToUploads do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    Ecto.Migration.execute "ALTER TYPE upload_status ADD VALUE IF NOT EXISTS 'downloading'"
    Ecto.Migration.execute "ALTER TYPE upload_status ADD VALUE IF NOT EXISTS 'downloading_failed'"
  end

  def down do
  end
end
