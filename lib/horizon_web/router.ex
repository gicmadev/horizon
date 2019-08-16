defmodule HorizonWeb.Router do
  use HorizonWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HorizonWeb do
    pipe_through :api

    get "/poc", DownloadController, :poc_download
    get "/dl/:dl_id", DownloadController, :download
    post "/upload", UploadController, :upload
  end
end
