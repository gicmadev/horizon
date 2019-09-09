import React, { useState, useEffect } from "react";

import { FilePond } from "react-filepond";

import "filepond/dist/filepond.min.css";

import { Box, Typography, Link } from "@material-ui/core";

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
  root: {
    maxWidth: "500px"
  }
});

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
  remove: (source, load, error) => {
    if (!source) return;

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

const UploaderBox = ({ upload_id, token, uploaded }) => {
  const classes = useStyles();
  const [files, setFiles] = useState([]);

  useEffect(
    () =>
      setFiles(
        uploaded ? [{ source: upload_id, options: { type: "local" } }] : []
      ),
    [uploaded]
  );
  console.log(files);

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
      <style>{`.filepond--root { margin-bottom: 0; }`}</style>
      <Box className={classes.root}>
        <FilePond
          files={files}
          allowMultiple={false}
          server={serverConfig(upload_id, token)}
          onupdatefiles={fileItems =>
            setFiles(fileItems.map(fileItem => fileItem.file))
          }
          name="horizon_file_upload"
          beforeRemoveFile={() =>
            confirm(
              "Confirmez-vous la suppression du fichier ?\nCette action est irréversible."
            )
          }
          {...uploaderPhrases}
        />
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
    </>
  );
};

export default UploaderBox;
