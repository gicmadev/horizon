import React from "react";
import ReactDOM from "react-dom";

import UploaderBox from "./components/UploaderBox";

window.loadHorizonUploader = (
  element,
  serverUrl,
  uploadId,
  token,
  url,
  urlImport,
  beforeDelete = (next, error) => next()
) => {
  window.reloadUploader = () => {
    ReactDOM.unmountComponentAtNode(element);
    ReactDOM.render(
      <UploaderBox
        serverUrl={serverUrl}
        uploadId={uploadId}
        token={token}
        url={url}
        urlImport={urlImport}
        beforeDelete={beforeDelete}
      />,
      element
    );
  };
  window.reloadUploader();
};

window.dispatchEvent(new Event("HorizonUploaderLoaded"));
