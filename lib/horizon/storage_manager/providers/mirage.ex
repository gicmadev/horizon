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
        File.mkdir_p!(get_dir(sha256))
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

  def unstore!(%{sha256: sha256} = blob) do
    path = get_path(sha256)

    case File.rm(path) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      _ -> File.rm!(path)
    end

    blob |> Repo.delete!()
  end

  def get_blob_path(%{remote_id: sha256, storage: @name}), do: get_path(sha256)

  defp get_path(sha256), do: get_dir(sha256) |> Path.join(sha256)

  defp get_dir(sha256) do
    @mirage_dir
    |> Path.join(
      sha256
      |> String.split("")
      |> Enum.slice(1, 6)
      |> Path.join()
    )
  end
end
