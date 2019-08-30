defmodule HorizonWeb.Router do
  use HorizonWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HorizonWeb do
    pipe_through :api

    get "/poc", DownloadController, :poc_download

    get "/upload/new", UploadController, :new
    post "/upload/:asset_id/cancel", UploadController, :burn
    post "/upload/:asset_id", UploadController, :upload
    get "/upload/:asset_id/status", UploadController, :status
    post "/upload/:asset_id/burn", UploadController, :burn

    get "/dl/:asset_id", DownloadController, :download
  end
end
