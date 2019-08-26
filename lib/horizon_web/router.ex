defmodule HorizonWeb.Router do
  use HorizonWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HorizonWeb do
    pipe_through :api

    get "/poc", DownloadController, :poc_download
    get "/dl/:ash_id", DownloadController, :download
    post "/upload", UploadController, :upload
    get "/upload/:ash_id/status", UploadController, :status
  end
end
