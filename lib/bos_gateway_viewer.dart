library bos_gateway_viewer;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:bos_gateway_viewer/services/localStorageCleaner/models/local_storage_cleaner.dart';
import 'package:bos_gateway_viewer/services/localStorageCleaner/unimplemented_ls_cleaner.dart'
    if (dart.library.io) 'package:bos_gateway_viewer/services/localStorageCleaner/mobile_ls_cleaner.dart'
    if (dart.library.js) 'package:bos_gateway_viewer/services/localStorageCleaner/web_ls_cleaner.dart';
import 'constants.dart';

part 'models/near_auth_creds.dart';
part 'models/widget_settings.dart';

final InAppLocalhostServer _localhostServer = InAppLocalhostServer(
  port: 8090,
  documentRoot: WebViewConstants.documentRoot,
);

class BosGatewayWidget extends StatefulWidget {
  const BosGatewayWidget(
      {super.key, required this.widgetSettings, required this.nearAuthCreds});

  final WidgetSettings widgetSettings;
  final NearAuthCreds nearAuthCreds;

  @override
  State<BosGatewayWidget> createState() => _BosGatewayWidgetState();
}

class _BosGatewayWidgetState extends State<BosGatewayWidget> {
  bool loading = true;
  bool pathWithProps = false;
  String newProps = """'{}'""";

  WidgetSettings get widgetSettings => widget.widgetSettings;
  NearAuthCreds get nearAuthCreds => widget.nearAuthCreds;

  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllowFullscreen: true,
    useWideViewPort: false,
  );

  Future<void> startViewer(InAppWebViewController webViewController) async {
    final String startView =
        '''window.startViewer("${nearAuthCreds.network.name}", "${widgetSettings.widgetSrc}", ${widgetSettings.widgetProps}, "${nearAuthCreds.accountId}", "${nearAuthCreds.privateKey}");''';
    return webViewController.evaluateJavascript(
      source: startView,
    );
  }

  Future<void> updateViewerWithNewProps({
    required InAppWebViewController webViewController,
    required String props,
  }) {
    final String startView =
        '''window.startViewer("${nearAuthCreds.network.name}", "${widgetSettings.widgetSrc}", $props, "${nearAuthCreds.accountId}", "${nearAuthCreds.privateKey}");''';
    return webViewController.evaluateJavascript(
      source: startView,
    );
  }

  String getWidgetPropsFormUrl(String url) {
    final Uri uri = Uri.parse(url);
    if (uri.queryParameters.isEmpty) {
      return """'{}'""";
    }
    final Map<String, dynamic> params = uri.queryParameters;
    final jsonString = jsonEncode(params);
    return """'$jsonString'""";
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    if (!_localhostServer.isRunning() && !kIsWeb) {
      await _localhostServer.start();
    }

    final LocalStorageCleaner localStorageCleanerManager =
        localStorageCleaner();
    await localStorageCleanerManager.clear();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialSettings: settings,
                  initialFile:
                      kIsWeb ? WebViewConstants.widgetAssetsPath : null,
                  initialUrlRequest: !kIsWeb
                      ? URLRequest(
                          url: WebUri(WebViewConstants.widgetWebviewUrl),
                        )
                      : null,
                  onWebViewCreated: (controller) {},
                  onPermissionRequest: (controller, request) async {
                    return PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.GRANT,
                    );
                  },
                  onLoadStart: (controller, url) {},
                  onLoadStop: (controller, url) async {
                    if (!pathWithProps) {
                      await startViewer(controller);
                    } else {
                      await updateViewerWithNewProps(
                        webViewController: controller,
                        props: newProps,
                      );
                    }
                    setState(() {
                      loading = false;
                    });
                  },
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                    final urlPath = url.toString();
                    if (urlPath == WebViewConstants.widgetWebviewUrl) {
                      return;
                    } else if (urlPath.contains(widgetSettings.widgetSrc)) {
                      final newProps = getWidgetPropsFormUrl(urlPath);
                      setState(() {
                        pathWithProps = true;
                        this.newProps = newProps;
                      });
                      controller.loadUrl(
                        urlRequest: URLRequest(
                          url: WebUri(WebViewConstants.widgetWebviewUrl),
                        ),
                      );
                    }
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    if (kDebugMode) {
                      print(consoleMessage);
                    }
                  },
                ),
                if (loading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
