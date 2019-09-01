defmodule Horizon.Schema.Upload do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias __MODULE__, as: Upload
  alias Horizon.Schema.Blob

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "uploads" do
    field :filename, :string, size: 512
    field :content_type, :string, size: 255, default: "application/octet-stream"
    field :sha256, :string, size: 64

    field :source, :string, size: 24
    field :bucket, :string, size: 24
    field :owner, :string, size: 24

    field :status, UploadStatusEnum

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:filename, :content_type, :sha256, :status])
    |> validate_format(:sha256, ~r/[A-Fa-f0-9]{64}/)
    |> validate_length(:filename, min: 1, max: 512)
    |> validate_length(:content_type, min: 1, max: 255)
    |> validate_required([:filename, :sha256, :content_type, :status])
  end

  def get_upload_and_blobs(upload_id, sha256) do
    Horizon.Repo.all(
      from(b in Blob,
        join: a in Upload,
        on: a.sha256 == b.sha256,
        where: a.id == ^upload_id and a.sha256 == ^sha256,
        select: %{
          id: a.id,
          status: a.status,
          filename: a.filename,
          sha256: a.sha256,
          storage: b.storage,
          remote_id: b.remote_id
        }
      )
    )
  end
end
