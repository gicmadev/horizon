import React from "react";
import { withStyles } from "@material-ui/styles";

import classnames from "classnames";

import { Box } from "@material-ui/core";

const styles = theme => ({
  contentBox: {
    width: "100%",
    maxWidth: "650px",
    margin: "15px auto",
    padding: "10px 0"
  }
});

const ContentBox = ({ classes, className, ...props }) => (
  <Box className={classnames(classes.contentBox, className)} {...props} />
);

export default withStyles(styles)(ContentBox);
