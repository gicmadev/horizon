defmodule Horizon.Schema.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resources" do
    field :remote_id, :string
    field :sha256, :string
    field :storage, ResourcesStorageEnum

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
