import React, { useState, useEffect } from "react";

import { Box, TextField, Button, Typography } from "@material-ui/core";

import ContentBox from "../ContentBox";
import InputsBox from "../InputsBox";

const RemoteURL = ({ hasHorizonUrl, onlineUrl, setOnlineUrl, toggleMode }) => (
  <ContentBox>
    <InputsBox>
      {hasHorizonUrl ? (
        <Box bgcolor="error.main" color="white" p={2} m={2}>
          <Typography variant="body2" align="justify">
            Attention, vous avez un fichier associé à votre publication. Il sera
            supprimé du stockage si vous sauvegardez maintenant.
          </Typography>
        </Box>
      ) : null}
      <TextField
        label="URL de votre média"
        placeholder="https://archive.org/download/MonPodcast/MonPodcast32.mp3"
        helperText="Lien direct vers le fichier uniquement (pas de page web)"
        name="item[enclosure_attributes][meta_url_attributes][remote][remote_path]"
        fullWidth
        margin="normal"
        InputLabelProps={{
          shrink: true
        }}
        value={onlineUrl}
        onChange={ev => setOnlineUrl(ev.target.value)}
      />
    </InputsBox>
    <Typography align="left">
      <Button color="primary" onClick={toggleMode}>
        Mon média est sur mon ordinateur
      </Button>
    </Typography>
  </ContentBox>
);

export default RemoteURL;
