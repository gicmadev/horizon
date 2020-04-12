defmodule Horizon.Repo.Migrations.AddDownloadingUrlAndErrorToUploads do
  use Ecto.Migration

  def change do
    alter table("uploads") do
      add(:downloading_url, :text)
      add(:downloading_error, :text)
    end
  end
end
