import React from "react";
import ReactDOM from "react-dom";

import UploaderBox from "./components/UploaderBox";

window.loadHorizonUploader = (element, upload_id, token, url) => {
  ReactDOM.render(
    <UploaderBox upload_id={upload_id} token={token} url={url} />,
    element
  );
};
