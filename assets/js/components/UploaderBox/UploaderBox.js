import React, { useState, useEffect } from "react";

import Uploader from "../Uploader";

import RemoteURL from "../RemoteURL";

const UploaderBox = props => {
  const { upload_id, token, url } = props;

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
          upload_id={upload_id}
          token={token}
          horizonUrl={horizonUrl}
          files={files}
          setHorizonUrl={setHorizonUrl}
          setFiles={setFiles}
          setFileUploaded={setFileUploaded}
          toggleMode={toggleMode}
        />
      ) : (
        <RemoteURL
          hasHorizonUrl={horizonUrl.length > 0}
          onlineUrl={onlineUrl}
          setOnlineUrl={setOnlineUrl}
          toggleMode={toggleMode}
        />
      )}
    </>
  );
};

export default UploaderBox;
