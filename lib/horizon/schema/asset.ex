defmodule Horizon.Schema.Asset do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias __MODULE__, as: Asset
  alias Horizon.Schema.Blob

  schema "assets" do
    field :filename, :string, size: 512
    field :content_type, :string, size: 255, default: "application/octet-stream"
    field :sha256, :string, size: 64
    field :status, AssetStatusEnum

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

  def get_asset_and_blobs(asset_id, sha256) do
    Horizon.Repo.all(
      from(b in Blob,
        join: a in Asset,
        on: a.sha256 == b.sha256,
        where: a.id == ^asset_id and a.sha256 == ^sha256,
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
