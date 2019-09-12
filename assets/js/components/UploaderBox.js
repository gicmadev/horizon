import React, { useState, useEffect } from "react";

import { FilePond, FileStatus } from "react-filepond";

import "filepond/dist/filepond.min.css";

import { TextField, Box, Button, Typography, Link } from "@material-ui/core";

import { makeStyles } from "@material-ui/styles";

const uploaderPhrases = {
  labelIdle:
    `Faites glisser votre fichier, ou ` +
    `<span class="filepond--label-action">cliquez pour parcourir...</span>`,
  labelInvalidField: `Fichier invalide`,
  labelFileWaitingForSize: `Récupération de la taille`,
  labelFileSizeNotAvailable: `Taille non disponible`,
  labelFileLoading: `Récupération`,
  labelFileLoadError: `Erreur de récupération`,
  labelFileProcessing: `Envoi`,
  labelFileProcessingComplete: `Envoi terminé`,
  labelFileProcessingAborted: `Envoi annulé`,
  labelFileProcessingError: `Erreur d'envoi`,
  labelFileProcessingRevertError: `Erreur d'annulation`,
  labelFileRemoveError: `Erreur de suppression`,
  labelTapToCancel: `Cliquez pour annuler`,
  labelTapToRetry: `Cliquez pour réessayer`,
  labelTapToUndo: `Cliquez pour annuler`,
  labelButtonRemoveItem: `Supprimer`,
  labelButtonAbortItemLoad: `Abandonner`,
  labelButtonRetryItemLoad: `Réessayer`,
  labelButtonAbortItemProcessing: `Annuler`,
  labelButtonUndoItemProcessing: `Annuler`,
  labelButtonRetryItemProcessing: `Réessayer`,
  labelButtonProcessItem: `Envoyer`
};

const useStyles = makeStyles({
  contentBox: {
    width: "100%",
    maxWidth: "600px",
    margin: "15px auto"
  },
  inputsBox: {
    width: "80%",
    maxWidth: "500px",
    margin: "auto"
  }
});

let delete_on_server = null;

const serverConfig = (upload_id, token) => ({
  url: process.env.REACT_APP_HORIZON_URL,
  process: {
    url: `/upload/${upload_id}`,
    method: "POST",
    withCredentials: false,
    headers: {
      Authorization: `Bearer ${token}`
    },
    onload: response => JSON.parse(response).id
  },
  revert: {
    url: `/upload/${upload_id}/revert`,
    method: "DELETE",
    withCredentials: false,
    headers: {
      Authorization: `Bearer ${token}`
    }
  },
  load: {
    url: `/upload/`,
    withCredentials: false,
    headers: {
      Authorization: `Bearer ${token}`
    }
  },
  remove: (server_id, load, error) => {
    // If source is undefined (error'd file) or
    // if we havn't confirmed deletion with user,
    // we just call load to continue removing file on client side only
    if (!server_id || server_id !== delete_on_server) return load();

    // If deletion has been user confirmed, we delete file on server,
    // and reset the variable
    delete_on_server = null;

    fetch([process.env.REACT_APP_HORIZON_URL, "upload", upload_id].join("/"), {
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

          if (result.ok === true && result.deleted === true) return load();

          return error("Invalid server response");
        },
        () => {
          error("non lol");
        }
      );
  },
  fetch: null
});

const UploaderBox = ({ upload_id, token, url }) => {
  const classes = useStyles();

  const [files, setFiles] = useState([]);
  const [mode, setMode] = useState("upload");

  const [horizonUrl, setHorizonUrl] = useState("");
  const [onlineUrl, setOnlineUrl] = useState("");

  const toggleMode = () => setMode(mode === "upload" ? "online" : "upload");

  const setFileUploaded = upload_id =>
    setFiles([{ source: upload_id, options: { type: "local" } }]);

  useEffect(() => {
    if (typeof url === "string") {
      if (url == `horizon://${upload_id}`) {
        setOnlineUrl("");
        setHorizonUrl(url);
        setMode("upload");
        setFileUploaded(upload_id);
      } else if (/^https?:\/\/.+/.test(url)) {
        setOnlineUrl(url);
        setHorizonUrl("");
        setMode("online");
        setFiles([]);
      } else {
        setOnlineUrl("");
        setHorizonUrl("");
        setMode("upload");
        setFiles([]);
      }
    }
  }, [url]);

  console.log(mode, files);

  return (
    <>
      <link
        rel="stylesheet"
        href="https://fonts.googleapis.com/css?family=Roboto:300,400,500,700&display=swap"
      />
      <link
        rel="stylesheet"
        href="https://fonts.googleapis.com/icon?family=Material+Icons"
      />
      {mode === "upload" ? (
        <>
          <style>{`.filepond--root { margin-bottom: 0; }`}</style>
          <Box className={classes.contentBox}>
            <Typography variant="caption" align="justify">
              En envoyant votre fichier sur nos serveurs pendant la phase de
              beta, vous acceptez le risque que votre fichier soit supprimé ou
              perdu, volontairement ou involontairement. Nous ferons notre
              possible pour éviter toute perte de données, mais nous vous
              conseillons de conserver les fichiers originaux par précaution.
            </Typography>
          </Box>
          <Box className={classes.inputsBox}>
            <FilePond
              files={files}
              allowMultiple={false}
              server={serverConfig(upload_id, token)}
              onupdatefiles={fileItems => {
                if (fileItems.length === 0) {
                  setHorizonUrl("");
                  setFiles([]);
                }
              }}
              onprocessfile={(error, file) => {
                if (file.status === FileStatus.PROCESSING_COMPLETE) {
                  setHorizonUrl(`horizon://${file.serverId}`);
                  setFileUploaded(file.serverId);
                }
              }}
              name="horizon_file_upload"
              beforeRemoveFile={obj => {
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
              }}
              {...uploaderPhrases}
            />
            <input
              type="hidden"
              name="item[enclosure_attributes][meta_url_attributes][remote][remote_path]"
              value={horizonUrl}
            />
            <pre>{horizonUrl}</pre>
            <Typography align="right">
              <Link
                href={`https://podcloud.fr/contact?purpose=storage&bug=${encodeURIComponent(
                  JSON.stringify({ upload_id, token, files })
                )}`}
                target="_blank"
                variant="body2"
              >
                Un problème?
              </Link>
            </Typography>
          </Box>
          <Box className={classes.contentBox}>
            <Typography align="left">
              <Button
                color="primary"
                className={classes.button}
                onClick={toggleMode}
              >
                Mon média est déjà en ligne
              </Button>
            </Typography>
          </Box>
        </>
      ) : (
        <>
          <Box className={classes.inputsBox}>
            {horizonUrl.length ? (
              <Box bgcolor="error.main" color="white" p={2} m={2}>
                <Typography variant="body2" align="justify">
                  Attention, vous avez un fichier associé à votre publication.
                  Il sera supprimé du stockage si vous sauvegardez maintenant.
                </Typography>
              </Box>
            ) : null}
            <TextField
              label="URL de votre média"
              placeholder="https://archive.org/download/MonPodcast/MonPodcast32.mp3"
              helperText="Lien direct vers le fichier uniquement (pas de page web)"
              name="item[enclosure_attributes][meta_url_attributes][remote][remote_path]"
              fullWidth
              margin="normal"
              InputLabelProps={{
                shrink: true
              }}
              value={onlineUrl}
              onChange={ev => setOnlineUrl(ev.target.value)}
            />
          </Box>
          <Box className={classes.contentBox}>
            <Typography align="left">
              <Button
                color="primary"
                className={classes.button}
                onClick={toggleMode}
              >
                Mon média est sur mon ordinateur
              </Button>
            </Typography>
          </Box>
        </>
      )}
    </>
  );
};

export default UploaderBox;
