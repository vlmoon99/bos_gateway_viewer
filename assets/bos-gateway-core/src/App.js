import * as nearAPI from "near-api-js";
import { Widget, useNear, useInitNear, useAccount } from "near-social-vm";
import { setupWalletSelector } from "@near-wallet-selector/core";
import { setupMyNearWallet } from "@near-wallet-selector/my-near-wallet";
import React, { useCallback, useEffect, useState } from "react";
import ls from "local-storage";
import "./App.scss";

const WalletSelectorAuthKey = "near_app_wallet_auth_key";

function App(props) {
  const network = props.network;
  const widgetSrc = props.widgetSrc;
  const widgetProps = props.widgetProps;
  const PRIVATE_KEY = props.privateKey;
  const accountId = props.accountId;

  console.log("NEAR objects will be initialized");
  console.log(network, widgetSrc, JSON.stringify(widgetProps), accountId, PRIVATE_KEY);

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

    initNear &&
      initNear({
        networkId: network,
        selector: setupWalletSelector({
          network: network,
          modules: [setupMyNearWallet()],
        }),
        config: {
          defaultFinality: undefined,
        },
      });

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
    return (
      <div>
        <Widget key={widgetSrc} src={widgetSrc} props={widgetProps} />
      </div>
    );
  }
}

export default App;
