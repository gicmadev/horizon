defmodule Horizon.Schema.File do
  use Ecto.Schema
  import Ecto.Changeset

  schema "files" do
    field :filename, :string, size: 512
    field :sha256, :string, size: 64

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:filename, :sha256])
    |> validate_format(:sha256, ~r/[A-Fa-f0-9]{64}/)
    |> validate_length(:filename, min: 1, max: 512)
    |> validate_required([:filename, :sha256])
  end
end
