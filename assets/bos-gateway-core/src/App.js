// import * as nearAPI from "near-api-js";
// import { Widget, useNear, useInitNear, useAccount } from "near-social-vm";
// import { BrowserRouter as Router, Link, Route, Switch } from "react-router-dom";
// import { setupWalletSelector } from "@near-wallet-selector/core";
// import { setupMyNearWallet } from "@near-wallet-selector/my-near-wallet";
// import React, { useCallback, useEffect, useState } from "react";
// import ls from "local-storage";
// import "./App.scss";
// import ViewPage from "./ViewPage";
// import { isValidAttribute } from "dompurify";

import React, { useCallback, useEffect, useState } from "react";
import * as nearAPI from "near-api-js";
import ls from "local-storage";
import "./App.scss";
import { BrowserRouter as Router, Link, Route, Switch } from "react-router-dom";
import ViewPage from "./ViewPage";
import { setupWalletSelector } from "@near-wallet-selector/core";
import { setupMyNearWallet } from "@near-wallet-selector/my-near-wallet";
import {
  Widget,
  useAccount,
  useInitNear,
  useNear,
  utils,
  EthersProviderContext,
} from "near-social-vm";
import { isValidAttribute } from "dompurify";

const WalletSelectorAuthKey = "near_app_wallet_auth_key";

const getNetworkPreset = (networkId) => {
  switch (networkId) {
    case "mainnet":
      return {
        networkId,
        nodeUrl: "https://rpc.fastnear.com",
        helperUrl: "https://helper.mainnet.near.org",
        explorerUrl: "https://nearblocks.io",
        indexerUrl: "https://api.kitwallet.app",
      };
    case "testnet":
      return {
        networkId,
        nodeUrl: "https://rpc.testnet.near.org",
        helperUrl: "https://helper.testnet.near.org",
        explorerUrl: "https://testnet.nearblocks.io",
        indexerUrl: "https://testnet-api.kitwallet.app",
      };
    default:
      throw Error(`Failed to find config for: '${networkId}'`);
  }
};

function App(props) {
  const network = props.network;
  const widgetSrc = props.widgetSrc;
  const widgetProps = JSON.parse(props.widgetProps);
  const PRIVATE_KEY = props.privateKey;
  const accountId = props.accountId;

  console.log("NEAR objects will be initialized");
  console.log(
    network,
    widgetSrc,
    JSON.stringify(widgetProps),
    accountId,
    PRIVATE_KEY
  );

  const anonymousWidget = PRIVATE_KEY === "" || accountId === "";

  const { initNear } = useInitNear();
  const near = useNear();
  const [isInitialized, setIsInitialized] = useState(false);
  const [nearInitialized, setNearInitialized] = useState(false);

  const WalletSelectorDefaultValues = {
    "near-wallet-selector:selectedWalletId": "near-wallet",
    "near-wallet-selector:recentlySignedInWallets": ["near-wallet"],
    "near-wallet-selector:contract": {
      contractId: network === "testnet" ? "v1.social08.testnet" : "social.near",
      methodNames: [],
    },
  };

  const walletSelectorNetwork = getNetworkPreset(network);

  useEffect(() => {
    const myKeyStore = new nearAPI.keyStores.BrowserLocalStorageKeyStore();
    async function setData() {
      ls.clear();
      const keyPair = nearAPI.KeyPair.fromString(PRIVATE_KEY);
      await myKeyStore.setKey(network, accountId, keyPair);
      Object.entries(WalletSelectorDefaultValues).forEach(([key, value]) => {
        ls.set(key, value);
      });
      ls.set(WalletSelectorAuthKey, {
        accountId: accountId,
        allKeys: [keyPair.publicKey.toString()],
      });
    }
    if (!anonymousWidget) {
      setData();
    }

    const config = {
      networkId: network,
      selector: setupWalletSelector({
        network: walletSelectorNetwork,
        modules: [setupMyNearWallet()],
      }),
      customElements: {
        Link: (props) => {
          if (!props.to && props.href) {
            props.to = props.href;
            delete props.href;
          }
          if (props.to) {
            props.to =
              typeof props.to === "string" &&
              isValidAttribute("a", "href", props.to)
                ? props.to
                : "about:blank";
          }
          return <Link {...props} />;
        },
      },
      config: {
        defaultFinality: undefined,
      },
    };

    initNear && initNear(config);

    setNearInitialized(true);
  }, [initNear]);

  useEffect(() => {
    async function loginInAccount() {
      const wallet = await (await near.selector).wallet("my-near-wallet");
      wallet.signIn({ contractId: near.config.contractName });
      setIsInitialized(true);
    }
    if (nearInitialized && !anonymousWidget) {
      loginInAccount();
    }
    if (anonymousWidget) {
      setIsInitialized(true);
    }
  }, [nearInitialized, near]);

  if (!isInitialized) {
    return (
      <div class="centered-spinner">
        <div class="spinner-grow" role="status">
          <span class="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  } else {
    const widgetSettings = {
      widgetSrc,
      widgetProps,
    };
    return (
      <Router>
        <ViewPage {...widgetSettings} />
      </Router>
    );
  }
}

export default App;
