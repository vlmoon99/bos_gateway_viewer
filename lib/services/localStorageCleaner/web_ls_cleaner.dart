import 'dart:js' as js;
import 'models/local_storage_cleaner.dart';

LocalStorageCleaner localStorageCleaner() => WebLocalStorageCleaner();

class WebLocalStorageCleaner implements LocalStorageCleaner {
  @override
  Future<void> clear() async {
    const String clearFunction = '''
        for (let i = localStorage.length - 1; i >= 0; i--) {
          const key = localStorage.key(i);
          if (key.startsWith("near")) {
            localStorage.removeItem(key);
          }
        }
      ''';
    return js.context.callMethod("eval", [clearFunction]);
  }
}
