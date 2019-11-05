import React from "react";
import ReactDOM from "react-dom";

import UploaderBox from "./components/UploaderBox";

window.loadHorizonUploader = (
  element,
  serverUrl,
  uploadId,
  token,
  url,
  beforeDelete = (next, error) => next()
) => {
  ReactDOM.render(
    <UploaderBox
      serverUrl={serverUrl}
      uploadId={uploadId}
      token={token}
      url={url}
      beforeDelete={beforeDelete}
    />,
    element
  );
};

window.dispatchEvent(new Event("HorizonUploaderLoaded"));
