import EctoEnum

defenum(BlobStorageEnum, :blob_storage, [:wasabi, :cloud_archive, :mirage])

defenum(UploadStatusEnum, :upload_status, [
  :new,
  :draft,
  :downloading,
  :downloading_failed,
  :processing,
  :ok
])
