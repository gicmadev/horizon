defmodule HorizonWeb.Router do
  use HorizonWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HorizonWeb do
    pipe_through :api

    get "/poc", DownloadController, :poc_download

    post "/upload/new", UploadController, :new

    scope "/upload/:upload_id/chunks" do
      options "/", UploadChunksController, :options
      options "/:uid", UploadChunksController, :options
      match :head, "/:uid", UploadChunksController, :head
      get "/:uid", UploadChunksController, :head
      post "/", UploadChunksController, :post
      patch "/:uid", UploadChunksController, :patch
      delete "/:uid", UploadChunksController, :delete
    end

    get "/upload/:upload_id", UploadController, :get

    delete "/upload/:upload_id/revert", UploadController, :revert
    delete "/upload/:upload_id", UploadController, :delete

    put "/upload/:upload_id/download", UploadController, :download

    post "/upload/:upload_id/burn", UploadController, :burn
    get "/upload/:upload_id/status", UploadController, :status

    get "/storage/status", StorageController, :status
    get "/storage/status/:owner", StorageController, :status

    get "/dl/:upload_id", DownloadController, :download
  end
end
