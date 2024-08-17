library bos_gateway_viewer;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  const BosGatewayWidget({
    super.key,
    required this.widgetSettings,
    required this.nearAuthCreds,
    this.onError,
  });

  final WidgetSettings widgetSettings;
  final NearAuthCreds nearAuthCreds;
  final Function(String errorMessage)? onError;

  @override
  State<BosGatewayWidget> createState() => _BosGatewayWidgetState();
}

class _BosGatewayWidgetState extends State<BosGatewayWidget> {
  late String newProps = widgetSettings.widgetProps;
  late String newPath = widgetSettings.widgetSrc;

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
    late String jsonString;
    if (uri.queryParameters.isNotEmpty) {
      final Map<String, dynamic> params = uri.queryParameters;
      jsonString = jsonEncode(params);
    } else if (url.lastIndexOf('?') != -1) {
      final subStr = url.substring(url.lastIndexOf('?') + 1);
      final Map<String, dynamic> params = Uri.splitQueryString(subStr);
      jsonString = jsonEncode(params);
    } else {
      jsonString = '{}';
    }
    return """'$jsonString'""";
  }

  String extractPath(String url) {
    // Parse the URL
    final uri = Uri.parse(url);

    // Split the path into segments
    List<String> segments = uri.pathSegments;

    // Find the index of 'widget'
    int widgetIndex = segments.indexOf('widget');

    // If 'widget' is found, reconstruct the path including the segment before and after 'widget'
    if (widgetIndex != -1) {
      String path = segments.sublist(widgetIndex - 1).join('/');
      return path;
    } else {
      String path = uri.fragment;
      if (path.lastIndexOf('?') != -1) {
        path = path.substring(1, path.lastIndexOf('?'));
        return path;
      } else {
        path = path.substring(
          1,
        );
        return path;
      }
    }
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    if (!_localhostServer.isRunning() && !kIsWeb) {
      await _localhostServer.start();
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
    }
  }

  @override
  void dispose() {
    localStorageCleaner().clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialSettings: settings,
      initialFile: kIsWeb ? WebViewConstants.widgetAssetsPath : null,
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
      onLoadStart: (controller, url) async {
        log("onLoadStart: ${url.toString()}");
      },
      onLoadStop: (controller, url) async {
        final urlPath = url.toString();
        if (kIsWeb) {
          if (urlPath.endsWith(WebViewConstants.widgetAssetsPath)) {
            await updateViewerWithNewParams(
              webViewController: controller,
              path: newPath,
              props: newProps,
            );
            return;
          }
          if (urlPath.contains("/widget/")) {
            final newPath = extractPath(urlPath);
            final newProps = getWidgetPropsFromUrl(urlPath);
            setState(() {
              this.newProps = newProps;
              this.newPath = newPath;
            });
            controller.loadFile(
                assetFilePath: WebViewConstants.widgetAssetsPath);
          } else {
            final newProps = getWidgetPropsFromUrl(urlPath);
            setState(() {
              this.newProps = newProps;
            });
            controller.loadFile(
                assetFilePath: WebViewConstants.widgetAssetsPath);
          }

          return;
        } else {
          if (urlPath == WebViewConstants.widgetWebviewUrl) {
            await updateViewerWithNewParams(
              webViewController: controller,
              path: newPath,
              props: newProps,
            );
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
          } else {
            final newProps = getWidgetPropsFromUrl(urlPath);
            setState(() {
              this.newProps = newProps;
            });
            controller.loadUrl(
              urlRequest: URLRequest(
                url: WebUri(WebViewConstants.widgetWebviewUrl),
              ),
            );
          }
        }
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) {},
      onLoadError: (controller, url, code, message) {
        controller.reload();
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
          widget.onError?.call(consoleMessage.message);
        }
      },
    );
  }
}
