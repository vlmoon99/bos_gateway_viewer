import 'package:dio/dio.dart';
import 'package:flutterchain/flutterchain_lib/constants/chains/near_blockchain_network_urls.dart';
import 'package:flutterchain/flutterchain_lib/constants/core/supported_blockchains.dart';
import 'package:flutterchain/flutterchain_lib/formaters/chains/near_formater.dart';
import 'package:flutterchain/flutterchain_lib/models/core/wallet.dart';
import 'package:flutterchain/flutterchain_lib/network/chains/near_rpc_client.dart';
import 'package:flutterchain/flutterchain_lib/services/chains/near_blockchain_service.dart';
import 'package:flutterchain/flutterchain_lib/services/core/crypto_service.dart';
import 'package:flutterchain/flutterchain_lib/services/core/js_engines/core/js_engine_stub.dart'
    if (dart.library.io) 'package:flutterchain/flutterchain_lib/services/core/js_engines/platforms_implementations/webview_js_engine.dart'
    if (dart.library.js) 'package:flutterchain/flutterchain_lib/services/core/js_engines/platforms_implementations/web_js_engine.dart';

class NearVM {
  Future<String> getFunctionalKeyForNearSocial({
    String network = "mainnet",
    required String accountId,
    required String privateKey,
    String allowance = "1",
  }) async {
    final FlutterChainService flutterChainService = FlutterChainService(
      jsVMService: getJsVM(),
      nearBlockchainService: NearBlockChainService(
        jsVMService: getJsVM(),
        nearRpcClient: NearRpcClient(
          networkClient: NearNetworkClient(
            dio: Dio(),
            baseUrl: NearBlockChainNetworkUrls.listOfUrls
                .elementAt(network == "testnet" ? 0 : 1),
          ),
        ),
      ),
    );
    final yoctoNearAllowance = NearFormatter.nearToYoctoNear(allowance);

    final nearBlockChainService = flutterChainService
        .blockchainServices[BlockChains.near] as NearBlockChainService;

    // generate hdwallet
    final generatedWallet = await flutterChainService.generateNewWallet(
        walletName: "GeneratedRandom ${DateTime.now()}");

    // get publicKey from private key
    final publicKey = await nearBlockChainService
        .getPublicKeyFromSecretKeyFromNearApiJSFormat(
            privateKey.split(":").last);

    //path for new generated keypair
    const derivationPathOfNewGeneratedAccount = DerivationPath(
      purpose: '44',
      coinType: '397',
      accountNumber: '0',
      change: '0',
      address: '2',
    );

    // get private key in base64
    final privateKeyBase64 = await nearBlockChainService
        .getPrivateKeyFromSecretKeyFromNearApiJSFormat(
            privateKey.split(":").last);

    // add key to wallet
    await nearBlockChainService.addKey(
      fromAddress: accountId,
      mnemonic: generatedWallet.mnemonic,
      derivationPathOfNewGeneratedAccount: derivationPathOfNewGeneratedAccount,
      permission: "functionCall",
      allowance: yoctoNearAllowance,
      smartContractId:
          network == "testnet" ? "v1.social08.testnet" : "social.near",
      methodNames: [],
      privateKey: privateKeyBase64,
      publicKey: publicKey,
    );

    // get blockchain data by derivation path
    final nearBlockChainData =
        await nearBlockChainService.getBlockChainDataByDerivationPath(
      mnemonic: generatedWallet.mnemonic,
      passphrase: "",
      derivationPath: derivationPathOfNewGeneratedAccount,
    );

    // export private key from new generated keypair
    return await nearBlockChainService.exportPrivateKeyToTheNearApiJsFormat(
        currentBlockchainData: nearBlockChainData,
      );
  }
}
