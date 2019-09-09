defmodule HorizonWeb.Router do
  use HorizonWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HorizonWeb do
    pipe_through :api

    get "/poc", DownloadController, :poc_download

    post "/upload/new", UploadController, :new

    post "/upload/:upload_id", UploadController, :upload
    options "/upload/:upload_id", UploadController, :options

    get "/upload/:upload_id", UploadController, :get

    delete "/upload/:upload_id/revert", UploadController, :revert
    delete "/upload/:upload_id", UploadController, :delete

    post "/upload/:upload_id/burn", UploadController, :burn
    get "/upload/:upload_id/status", UploadController, :status

    get "/dl/:upload_id", DownloadController, :download
  end
end
