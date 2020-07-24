import React, { useState, useEffect } from "react";

import { FilePond } from "react-filepond";

import { Button, Typography, Link } from "@material-ui/core";

import ContentBox from "../ContentBox";
import InputsBox from "../InputsBox";

import "filepond/dist/filepond.min.css";
import "./Uploader.styles.css";

import useUploaderPhrases from "./Uploader.intl";

import useUploaderConfig from "./Uploader.config";

import logger from "../../utils/logger.js";

const Uploader = props => {
  const { uploadId, token, horizonUrl, files, toggleMode, hasProblem } = props;

  return (
    <ContentBox>
      <Typography variant="caption" align="justify">
        Malgré le soin apporté à l'élaboration de notre service, aucun système
        n'est fiable à 100%, nous vous conseillons de conserver les fichiers
        originaux par précaution.
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
          {hasProblem ? (
            <Typography variant="caption" align="justify">
              Le module d'envoi à été rechargé. Si votre problème n'est pas
              résolu, vous pouvez{" "}
              <Link
                href="#"
                onClick={() => {
                  logger.log("clicking on contact us");

                  const form = document.createElement("form");
                  form.action = `/uploader-issue`;
                  form.method = "POST";
                  form.target = "_blank";

                  const purposeInput = document.createElement("input");
                  purposeInput.name = "purpose";
                  purposeInput.type = "hidden";
                  purposeInput.value = "storage";
                  form.appendChild(purposeInput);

                  const bugInput = document.createElement("input");
                  bugInput.name = "bug";
                  bugInput.type = "hidden";
                  bugInput.value = window.btoa(
                    JSON.stringify({
                      uploadId,
                      token,
                      files,
                      logs: logger.getLogs()
                    })
                  );
                  form.appendChild(bugInput);

                  document.body.appendChild(form);

                  form.submit();

                  return false;
                }}
                variant="body2"
              >
                nous contacter
              </Link>
              .
            </Typography>
          ) : (
            <Link
              href="#"
              onClick={() => {
                logger.log("clicking on has problem");
                window.reloadUploader(true);

                return false;
              }}
              variant="body2"
            >
              Un problème?
            </Link>
          )}
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
