import { FileStatus } from "react-filepond";

const FakeBlob = class extends Blob {
  constructor(data) {
    super();
    Object.defineProperties(this, {
      size: { get: () => data.size, set: () => {} },
      name: { get: () => data.name, set: () => {} },
      type: { get: () => data.type, set: () => {} }
    });
  }

  slice(start, end, type) {
    return this;
  }
};

const useUploaderConfig = ({
  serverUrl,
  uploadId,
  token,
  files,
  setHorizonUrl,
  setFiles,
  setFileUploaded,
  beforeDelete
}) => {
  let delete_on_server = null;

  return {
    allowMultiple: false,
    files: files,
    name: "horizon_file_upload",
    server: {
      url: serverUrl,
      process: {
        url: `/upload/${uploadId}`,
        method: "POST",
        withCredentials: false,
        headers: {
          Authorization: `Bearer ${token}`
        },
        onload: response => JSON.parse(response).id
      },
      revert: {
        url: `/upload/${uploadId}/revert`,
        method: "DELETE",
        withCredentials: false,
        headers: {
          Authorization: `Bearer ${token}`
        }
      },
      load: (server_id, load, error, progress, abort, headers) => {
        if (!server_id) return;

        const controller = new AbortController();
        const signal = controller.signal;

        fetch([serverUrl, "upload", server_id].join("/"), {
          signal,
          headers: {
            Authorization: `Bearer ${token}`
          }
        })
          .then(resp => resp.json())
          .then(
            body =>
              body.errors
                ? error(body.errors.detail || body.errors)
                : load(new FakeBlob(body)),
            err => error(err)
          );

        return {
          abort: () => {
            controller.abort();
            abort();
          }
        };
      },
      remove: (server_id, load, error) => {
        // If source is undefined (error'd file) or
        // if we havn't confirmed deletion with user,
        // we just call load to continue removing file on client side only
        if (!server_id || server_id !== delete_on_server) return load();

        // If deletion has been user confirmed, we delete file on server,
        // and reset the variable
        delete_on_server = null;

        return beforeDelete(
          () =>
            fetch([serverUrl, "upload", uploadId].join("/"), {
              method: "DELETE",

              headers: {
                Authorization: `Bearer ${token}`
              }
            })
              .then(result => result.json())
              .then(
                result => {
                  if (typeof result !== "object")
                    return error("Invalid server response");

                  if (result.errors) {
                    if (result.errors.detail === "Not Found") {
                      return load();
                    } else if (typeof result.errors.detail === "string") {
                      return error(result.errors.detail);
                    }
                  }

                  if (result.ok === true && result.deleted === true)
                    return load();

                  return error("Invalid server response");
                },
                () => {
                  return error("Invalid server response");
                }
              ),
          error
        );
      },
      fetch: null
    },
    beforeRemoveFile: obj => {
      // We allow removing of the file if it errored out
      if (
        [
          FileStatus.LOAD_ERROR,
          FileStatus.PROCESSING_ERROR,
          FileStatus.PROCESSING_REVERT_ERROR
        ].includes(obj.status)
      )
        return true;

      // If file is fully loaded, we ask for confirmation before remove
      if (
        confirm(
          "Confirmez-vous la suppression du fichier ?\nCette action est irréversible."
        )
      ) {
        // We set this variable to be sure deletion has been confirmed
        delete_on_server = obj.serverId;

        return true;
      }

      // We stop the deletion process with false if it hasn't been confirmed
      return false;
    },
    onupdatefiles: fileItems => {
      if (fileItems.length === 0) {
        setHorizonUrl("");
        setFiles([]);
      }
    },
    onprocessfile: (error, file) => {
      if (file.status === FileStatus.PROCESSING_COMPLETE) {
        setHorizonUrl(`horizon://${file.serverId}`);
        setFileUploaded(file.serverId);
      }
    }
  };
};

export default useUploaderConfig;
