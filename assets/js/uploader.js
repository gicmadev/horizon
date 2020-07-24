import React from "react";
import ReactDOM from "react-dom";

import UploaderBox from "./components/UploaderBox";

import logger from "./utils/logger.js";

window.loadHorizonUploader = (
  element,
  serverUrl,
  uploadId,
  token,
  url,
  urlImport,
  beforeDelete = (next, error) => next()
) => {
  logger.log("loading uploader");
  window.reloadUploader = hasProblem => {
    logger.log("calling reloadUploader with hasProblem", hasProblem);
    ReactDOM.unmountComponentAtNode(element);
    ReactDOM.render(
      <UploaderBox
        serverUrl={serverUrl}
        uploadId={uploadId}
        token={token}
        url={url}
        urlImport={urlImport}
        beforeDelete={beforeDelete}
        hasProblem={hasProblem}
      />,
      element
    );
  };
  window.reloadUploader();
};

logger.log("dispatching HorizonUploaderLoaded");
window.dispatchEvent(new Event("HorizonUploaderLoaded"));
