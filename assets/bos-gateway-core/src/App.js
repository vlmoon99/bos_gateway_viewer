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

const getNetworkPreset = (networkId) => ({
  mainnet: {
    networkId,
    nodeUrl: "https://rpc.fastnear.com",
    helperUrl: "https://helper.mainnet.near.org",
    explorerUrl: "https://nearblocks.io",
    indexerUrl: "https://api.kitwallet.app",
  },
  testnet: {
    networkId,
    nodeUrl: "https://rpc.testnet.near.org",
    helperUrl: "https://helper.testnet.near.org",
    explorerUrl: "https://testnet.nearblocks.io",
    indexerUrl: "https://testnet-api.kitwallet.app",
  },
})[networkId];

function App(props) {
  const { network, widgetSrc, widgetProps, privateKey, accountId } = props;
  const anonymousWidget = !privateKey || !accountId;

  console.log("NEAR objects will be initialized");
  console.log(JSON.stringify(props));

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
      for (let i = localStorage.length - 1; i >= 0; i--) {
        const key = localStorage.key(i);
        if (key.startsWith("near")) {
          localStorage.removeItem(key);
        }
      }
      const keyPair = nearAPI.KeyPair.fromString(privateKey);
      await myKeyStore.setKey(network, accountId, keyPair);
      Object.entries(WalletSelectorDefaultValues).forEach(([key, value]) => {
        ls.set(key, value);
      });
      ls.set(WalletSelectorAuthKey, {
        accountId,
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
        nodeUrl: walletSelectorNetwork.nodeUrl,
      },
    };

    initNear && initNear(config);

    setNearInitialized(true);
  }, [initNear, network, privateKey, accountId, anonymousWidget]);

  useEffect(() => {
    async function loginInAccount() {
      const wallet = await (await near.selector).wallet("my-near-wallet");
      wallet.signIn({ contractId: near.config.contractName });
      setIsInitialized(true);
    }
    if (nearInitialized && !anonymousWidget) {
      loginInAccount();
    } else if (anonymousWidget) {
      setIsInitialized(true);
    }
  }, [nearInitialized, near, anonymousWidget]);

  return (
    <div className="App">
      {isInitialized ? (
        <Router>
          <Route>
            <ViewPage widgetSrc={widgetSrc} widgetProps={JSON.parse(widgetProps)} />
          </Route>
        </Router>
      ) : (
        <div className="centered-spinner">
          <div className="spinner-grow" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
