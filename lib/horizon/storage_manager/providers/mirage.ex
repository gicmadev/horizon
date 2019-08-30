defmodule Horizon.StorageManager.Provider.Mirage do
  use Horizon.StorageManager.Provider

  alias Horizon.Repo
  alias Horizon.Schema.Blob

  @name :mirage
  @mirage_dir "/downloads"

  def name, do: @name

  def store!(file, %{sha256: sha256}) do
    res = Repo.get_by(Blob, sha256: sha256, storage: :mirage)

    case res do
      nil ->
        File.cp!(file.path, get_path(sha256))

        Repo.insert!(
          Blob.changeset(%Blob{}, %{
            sha256: sha256,
            storage: @name,
            remote_id: sha256
          })
        )

      res ->
        res
    end
  end

  def get_blob_path(%{remote_id: sha256, storage: @name}), do: get_path(sha256)

  defp get_path(sha256), do: Path.join(@mirage_dir, sha256)
end
