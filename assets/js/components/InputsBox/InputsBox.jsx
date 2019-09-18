import React from "react";
import { withStyles } from "@material-ui/styles";

import { Box } from "@material-ui/core";

import classnames from "classnames";

const styles = theme => ({
  inputsBox: {
    width: "80%",
    maxWidth: "570px",
    margin: "25px auto"
  }
});

const InputsBox = ({ classes, className, ...props }) => (
  <Box className={classnames(classes.inputsBox, className)} {...props} />
);

export default withStyles(styles)(InputsBox);
