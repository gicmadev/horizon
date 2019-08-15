defmodule Horizon.Schema.Blob do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blobs" do
    field :remote_id, :string
    field :sha256, :string
    field :storage, BlobStorageEnum

    timestamps()
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:sha256, :storage, :remote_id])
    |> validate_required([:sha256, :storage, :remote_id])
    |> validate_format(:sha256, ~r/[A-Fa-f0-9]{64}/)
  end
end
