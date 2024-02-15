part of "../bos_gateway_viewer.dart";

enum NearNetwork { mainnet, testnet }

@immutable
class NearAuthCreds {
  final NearNetwork network;
  final String accountId;
  final String privateKey;

  const NearAuthCreds({
    required this.network,
    String? accountId,
    String? privateKey,
  })  : assert(
          (accountId == null && privateKey == null) ||
              (accountId != null && privateKey != null),
          'accountId and privateKey must both be inserted or both be non-inserted',
        ),
        accountId = accountId ?? "",
        privateKey = privateKey ?? "";
}
