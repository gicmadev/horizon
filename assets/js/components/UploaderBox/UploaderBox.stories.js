import React from "react";

import { storiesOf } from "@storybook/react";
import { withKnobs, text, boolean } from "@storybook/addon-knobs";

import UploaderBox from "./UploaderBox";

storiesOf("UploaderBox", module)
  .addDecorator(withKnobs)
  .add("base", () => (
    <UploaderBox
      serverUrl={"https://horizon.podcloud.test/"}
      uploadId={text("Upload ID")}
      token={text("Upload JWT Token")}
      url={text("Known URL")}
    />
  ));
