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
  String newProps = "";
  String newPath = "";

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

  Future<void> updateViewerWithNewParams({
    required InAppWebViewController webViewController,
    required String path,
    required String props,
  }) {
    final String startView =
        '''window.startViewer("${nearAuthCreds.network.name}", "$path", $props, "${nearAuthCreds.accountId}", "${nearAuthCreds.privateKey}");''';
    return webViewController.evaluateJavascript(
      source: startView,
    );
  }

  String getWidgetPropsFromUrl(String url) {
    final Uri uri = Uri.parse(url);
    if (uri.queryParameters.isEmpty) {
      return """'{}'""";
    }
    final Map<String, dynamic> params = uri.queryParameters;
    final jsonString = jsonEncode(params);
    return """'$jsonString'""";
  }

  String extractPath(String url) {
    // Parse the URL
    final uri = Uri.parse(url);

    // Split the path into segments
    List<String> segments = uri.pathSegments;

    // Reconstruct the path by joining the relevant segments
    String path =
        segments.takeWhile((segment) => segment != 'widget').join('/') +
            '/widget';

    // Append the rest of the path after 'widget'
    int widgetIndex = segments.indexOf('widget');
    if (widgetIndex != -1 && widgetIndex + 1 < segments.length) {
      path += '/' + segments.sublist(widgetIndex + 1).join('/');
    }

    return path;
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
            onLoadStart: (controller, url) async {},
            onLoadStop: (controller, url) async {
              if (loading) {
                await startViewer(controller);
                setState(() {
                  loading = false;
                });
              } else {
                updateViewerWithNewParams(
                  webViewController: controller,
                  path: newPath,
                  props: newProps,
                );
              }
            },
            onUpdateVisitedHistory: (controller, url, androidIsReload) {
              final urlPath = url.toString();
              if (urlPath == WebViewConstants.widgetWebviewUrl) {
                return;
              }
              if (urlPath.contains("/widget/")) {
                final newPath = extractPath(urlPath);
                final newProps = getWidgetPropsFromUrl(urlPath);
                setState(() {
                  this.newProps = newProps;
                  this.newPath = newPath;
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
    );
  }
}
