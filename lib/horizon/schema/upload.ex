defmodule Horizon.Schema.Upload do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias __MODULE__, as: Upload
  alias Horizon.Schema.Blob

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @default_content_type "application/octet-stream"

  schema "uploads" do
    field :filename, :string, size: 512
    field :content_type, :string, size: 255, default: @default_content_type
    field :content_length, :integer
    field :sha256, :string, size: 64

    field :duration, :integer
    field :artwork, :binary

    field :source, :string, size: 24
    field :bucket, :string, size: 24
    field :owner, :string, size: 24

    field :downloading_url, :string
    field :downloading_error, :string

    field :status, UploadStatusEnum

    timestamps()
  end

  @doc false
  def new(attrs) do
    %Upload{}
    |> cast(attrs, [:source, :bucket, :owner])
    |> set_status(:new)
    |> validate_length(:source, min: 1, max: 24)
    |> validate_length(:bucket, min: 1, max: 24)
    |> validate_length(:owner, min: 1, max: 24)
    |> validate_required([:source, :bucket, :owner])
  end

  @doc false
  def downloading(upload, url) do
    upload
    |> cast(%{downloading_error: nil, downloading_url: url}, [
      :downloading_error,
      :downloading_url
    ])
    |> set_status(:downloading)
  end

  @doc false
  def fail_downloading(upload, error) do
    upload
    |> cast(%{downloading_error: Poison.encode!(error)}, [:downloading_error])
    |> set_status(:downloading_failed)
  end

  @doc false
  def reset(upload) do
    upload
    |> cast(
      %{
        filename: nil,
        content_length: nil,
        content_type: nil,
        sha256: nil,
        downloading_url: nil,
        downloading_error: nil,
        artwork: nil,
        duration: nil
      },
      [
        :filename,
        :content_length,
        :content_type,
        :sha256,
        :downloading_url,
        :downloading_error,
        :artwork,
        :duration
      ]
    )
    |> set_status(:new)
  end

  @doc false
  def upload(upload, attrs) do
    upload
    |> cast(attrs, [:filename, :content_type, :content_length, :sha256, :duration, :artwork])
    |> set_status(:draft)
    |> validate_format(:sha256, ~r/[A-Fa-f0-9]{64}/)
    |> validate_length(:filename, min: 1, max: 512)
    |> validate_length(:content_type, min: 1, max: 255)
    |> validate_number(:content_length, greater_than: 0)
    |> validate_required([:filename, :sha256, :content_type, :content_length])
  end

  @doc false
  def burn(upload) do
    upload
    |> set_status(:ok)
  end

  @doc false
  def move(upload, owner, bucket, source) do
    upload
    |> cast(%{owner: owner, bucket: bucket, source: source}, [:owner, :bucket, :source])
  end

  @doc false
  def write_metadata(upload, attrs) do
    upload
    |> cast(attrs, [:duration, :artwork])
  end

  defp set_status(upload, status), do: upload |> cast(%{status: status}, [:status])

  def get_upload_and_blobs(upload_id) do
    Horizon.Repo.all(
      from(b in Blob,
        join: a in Upload,
        on: a.sha256 == b.sha256,
        where: a.id == ^upload_id and a.status == ^:ok,
        select: %{
          id: a.id,
          status: a.status,
          filename: a.filename,
          content_type: a.content_type,
          sha256: a.sha256,
          storage: b.storage,
          remote_id: b.remote_id
        }
      )
    )
  end
end
