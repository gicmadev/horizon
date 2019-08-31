defmodule HorizonWeb.Router do
  use HorizonWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HorizonWeb do
    pipe_through :api

    get "/poc", DownloadController, :poc_download

    get "/upload/new", UploadController, :new

    get "/upload/:asset_id/ensure", UploadController, :ensure

    post "/upload/:asset_id", UploadController, :upload
    post "/upload/:asset_id/cancel", UploadController, :cancel

    post "/upload/:asset_id/burn", UploadController, :burn
    get "/upload/:asset_id/status", UploadController, :status

    get "/dl/:asset_id", DownloadController, :download
  end
end
