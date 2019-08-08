defmodule Horizon.StorageManager.Provider do
  @doc """
  Returns storage provider codename
  """
  @callback name() :: String.t()

  @doc """
  Store file into storage provider
  """
  @callback store(file_path :: String.t()) ::
              {:ok, remote_id :: String.t()} | {:error, String.t()}

  defmacro __using__(_) do
    quote do
      @behaviour Horizon.StorageManager.Provider
    end
  end
end
