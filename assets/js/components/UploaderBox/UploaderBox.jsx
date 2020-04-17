import React, { useState, useEffect } from "react";

import Uploader from "../Uploader";

import RemoteURL from "../RemoteURL";

const UploaderBox = props => {
  const { serverUrl, uploadId, token, url, urlImport, beforeDelete } = props;

  const [files, setFiles] = useState([]);
  const [mode, setMode] = useState("upload");

  const [horizonUrl, setHorizonUrl] = useState("");
  const [onlineUrl, setOnlineUrl] = useState("");
  const [onlineUrlImport, setOnlineUrlImport] = useState(!!urlImport);

  const toggleMode = () => setMode(mode === "upload" ? "online" : "upload");

  const setFileUploaded = uploadId =>
    setFiles([{ source: uploadId, options: { type: "local" } }]);

  useEffect(() => {
    if (typeof url === "string") {
      if (url == `horizon://${uploadId}`) {
        setOnlineUrl("");
        setHorizonUrl(url);
        setMode("upload");
        setFileUploaded(uploadId);
        console.log("already uploaded");
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

  return (
    <>
      <input
        type="hidden"
        name="item[enclosure_attributes][meta_url_attributes][source]"
        value="remote"
      />
      {mode === "upload" ? (
        <Uploader
          serverUrl={serverUrl}
          uploadId={uploadId}
          token={token}
          horizonUrl={horizonUrl}
          files={files}
          setHorizonUrl={setHorizonUrl}
          setFiles={setFiles}
          setFileUploaded={setFileUploaded}
          toggleMode={toggleMode}
          beforeDelete={beforeDelete}
        />
      ) : (
        <RemoteURL
          hasHorizonUrl={horizonUrl.length > 0}
          onlineUrl={onlineUrl}
          setOnlineUrl={setOnlineUrl}
          onlineUrlImport={onlineUrlImport}
          setOnlineUrlImport={setOnlineUrlImport}
          toggleMode={toggleMode}
        />
      )}
    </>
  );
};

export default UploaderBox;
