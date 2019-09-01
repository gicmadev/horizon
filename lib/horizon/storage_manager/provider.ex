defmodule Horizon.StorageManager.Provider do
  alias Horizon.Schema.{Upload, Blob}

  @doc """
  Returns storage provider codename
  """
  @callback name() :: String.t()

  @doc """
  Store file into storage provider
  """
  @callback store!(file_path :: String.t(), %Upload{}) :: %Blob{}

  defmacro __using__(_) do
    quote do
      @behaviour Horizon.StorageManager.Provider
    end
  end
end
