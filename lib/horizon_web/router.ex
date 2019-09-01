defmodule HorizonWeb.Router do
  use HorizonWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HorizonWeb do
    pipe_through :api

    get "/poc", DownloadController, :poc_download

    get "/upload/new", UploadController, :new

    get "/upload/:upload_id/ensure", UploadController, :ensure

    post "/upload/:upload_id", UploadController, :upload
    post "/upload/:upload_id/cancel", UploadController, :cancel

    post "/upload/:upload_id/burn", UploadController, :burn
    get "/upload/:upload_id/status", UploadController, :status

    get "/dl/:upload_id", DownloadController, :download
  end
end
