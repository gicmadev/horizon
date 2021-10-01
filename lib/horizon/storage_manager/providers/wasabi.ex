defmodule Horizon.StorageManager.Provider.Wasabi do
  @moduledoc "Manage blobs on Wasabi storage"

  use Horizon.StorageManager.Provider

  require Logger

  alias Horizon.Repo
  alias Horizon.Schema.Blob

  alias __MODULE__
  alias ExAws.S3

  @name :wasabi

  @bucket Application.get_env(:ex_aws, :s3)[:bucket]

  def name, do: @name

  def store!(%{path: file_path}, %{sha256: sha256}) do
    res = Repo.get_by(Blob, sha256: sha256, storage: @name)

    case res do
      nil ->
        Wasabi.UploadManager.upload(file_path, sha256, @bucket, get_path(sha256), self())

        receive do
          {:uploaded, ^sha256} ->
            Repo.insert!(
              Blob.changeset(%Blob{}, %{
                sha256: sha256,
                storage: @name,
                remote_id: sha256
              })
            )
        end

      res ->
        res
    end
  end

  def unstore!(%Blob{sha256: sha256} = blob) do
    S3.delete_object(@bucket, get_path(sha256))
    blob |> Repo.delete!()
  end

  def get_blob_path(%{sha256: sha256, storage: @name}), do: get_path(sha256)

  defp get_path(sha256), do: get_dir(sha256) |> Path.join(sha256)

  defp get_dir(sha256) do
    sha256
    |> String.split("")
    |> Enum.slice(1, 6)
    |> Path.join()
  end
end
