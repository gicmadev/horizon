import React, { useState, useEffect } from "react";

import { Button, Typography, Link } from "@material-ui/core";

import ContentBox from "../ContentBox";
import InputsBox from "../InputsBox";

import "filepond/dist/filepond.min.css";
import "./FileUploader.styles.css";

const FileUploader = props => {
  const { serverUrl, uploadId, token } = props;

  const [file, setFile] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`${serverUrl}upload/${uploadId}`, {
      headers: {
        authorization: `Bearer ${token}`
      }
    })
      .then(res => res.json())
      .then(setFile)
      .then(undefined, err => setFile({ error: err }));
  }, []);

  return <pre>{JSON.stringify(file, null, 3)}</pre>;
};

export default FileUploader;
