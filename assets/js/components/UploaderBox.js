import React, { useState } from "react";

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

const UploaderBox = ({ item_id }) => {
  const classes = useStyles();
  const [files, setFiles] = useState([]);

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
          server="/api"
          onupdatefiles={fileItems =>
            setFiles(fileItems.map(fileItem => fileItem.file))
          }
          {...uploaderPhrases}
        />
        <Typography align="right">
          <Link
            href={`https://podcloud.fr/contact?purpose=storage&bug=${encodeURIComponent(
              JSON.stringify({ item_id, files })
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
