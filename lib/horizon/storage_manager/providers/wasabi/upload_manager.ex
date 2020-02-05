defmodule Horizon.StorageManager.Provider.Wasabi.UploadManager do
  @moduledoc "Uniquely starts uploads"

  use Supervisor

  alias __MODULE__
  alias Horizon.StorageManager.Provider.Wasabi
  alias UploadManager.UploadsSupervisor

  alias Wasabi.Uploader

  @registry :uploads_registry

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {DynamicSupervisor, name: UploadsSupervisor, strategy: :one_for_one},
      {Registry, [keys: :unique, name: @registry]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def upload(file_path, bucket, sha256, remote_path, provider_id) do
    if Enum.empty?(Registry.lookup(@registry, file_path)) do
      DynamicSupervisor.start_child(
        UploadsSupervisor,
        %{
          id: Uploader,
          start: {Uploader, :start, [file_path, bucket, sha256, remote_path, provider_id]},
          restart: :temporary,
          name: {:via, Registry, {@registry, file_path}}
        }
      )
    end
  end
end
