import "core-js";
import React from "react";
import ReactDOM from "react-dom";
import App from "./App";

const mountNode = document.getElementById("app");

function startViewer(network, widgetSrc, widgetProps, accountId, privateKey) {
    ReactDOM.render(<App network={network} widgetSrc={widgetSrc} widgetProps={widgetProps} accountId={accountId} privateKey={privateKey} />, mountNode);
}

window.startViewer = startViewer;

//Example of usage
// startViewer("mainnet", "vlmoon.near/widget/ProfileEditor", {}, "bosmobile.near", "ed25519:5tbP6myFeFztTaCk25E8XkXeMvmxeUL9T4cJppKhSnFJsPA9NYBzPhu9eNMCVC9KBhTkKk6s8bGyGG28dUczSJ7v");
