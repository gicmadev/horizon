defmodule HorizonWeb.Router do
  use HorizonWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HorizonWeb do
    pipe_through :api

    get "/download", DownloadController, :download
  end
end
