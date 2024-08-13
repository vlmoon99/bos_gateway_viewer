// import "core-js";
import "core-js/features";
import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App";

const container = document.getElementById("app");
const root = createRoot(container);

function startViewer(network, widgetSrc, widgetProps, accountId, privateKey) {
  root.render(
    <App
      network={network}
      widgetSrc={widgetSrc}
      widgetProps={widgetProps}
      accountId={accountId}
      privateKey={privateKey}
    />
  );
}

window.startViewer = startViewer;

//Example of usage
// startViewer("mainnet", "devhub.near/widget/app", '{"page": "proposals"}', "bosmobile.near", "ed25519:5tbP6myFeFztTaCk25E8XkXeMvmxeUL9T4cJppKhSnFJsPA9NYBzPhu9eNMCVC9KBhTkKk6s8bGyGG28dUczSJ7v");
