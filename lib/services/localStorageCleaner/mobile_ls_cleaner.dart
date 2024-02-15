import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'models/local_storage_cleaner.dart';

LocalStorageCleaner localStorageCleaner() => MobileLocalStorageCleaner();

class MobileLocalStorageCleaner implements LocalStorageCleaner {
  final WebStorageManager _webStorageManager = WebStorageManager();

  @override
  Future<void> clear() async {
    final DateTime date = DateTime.now().subtract(
      const Duration(days: 1000),
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _webStorageManager.deleteAllData();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _webStorageManager.removeDataModifiedSince(
        dataTypes: {WebsiteDataType.WKWebsiteDataTypeLocalStorage},
        date: date,
      );
    }
  }
}
