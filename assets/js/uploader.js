import '../css/app.css';

import React from 'react';
import ReactDOM from 'react-dom';

import UploaderBox from './components/UploaderBox';

window.loadHorizonUploader = (element) => {
    if(window.loadedHorizonUploader) return;

    window.loadedHorizonUploader = true;
    ReactDOM.render(<UploaderBox />, element);
}
