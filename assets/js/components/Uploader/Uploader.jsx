import React, { useState, useEffect } from "react";

import { FilePond } from "react-filepond";

import { Button, Typography, Link } from "@material-ui/core";

import ContentBox from "../ContentBox";
import InputsBox from "../InputsBox";

import "filepond/dist/filepond.min.css";
import "./Uploader.styles.css";

import useUploaderPhrases from "./Uploader.intl";

import useUploaderConfig from "./Uploader.config";

const Uploader = props => {
  const { upload_id, token, horizonUrl, files, toggleMode } = props;

  return (
    <ContentBox>
      <Typography variant="caption" align="justify">
        En envoyant votre fichier sur nos serveurs pendant la phase de beta,
        vous acceptez le risque que votre fichier soit supprimé ou perdu,
        volontairement ou involontairement. Nous ferons notre possible pour
        éviter toute perte de données, mais nous vous conseillons de conserver
        les fichiers originaux par précaution.
      </Typography>
      <InputsBox>
        <FilePond
          {...useUploaderConfig(props)}
          {...useUploaderPhrases(props)}
        />
        <input
          type="hidden"
          name="item[enclosure_attributes][meta_url_attributes][remote][remote_path]"
          value={horizonUrl}
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
      </InputsBox>
      <Typography align="left">
        <Button color="primary" onClick={toggleMode}>
          Mon média est déjà en ligne
        </Button>
      </Typography>
    </ContentBox>
  );
};

export default Uploader;
