Viewer for bos-gateway-core

## Requirements

- Dart sdk: ">=3.5.0"
- Flutter: ">=3.24.0"
- Android: `minSdkVersion >= 19`, `compileSdk >= 34`, [AGP](https://developer.android.com/build/releases/gradle-plugin) version `>= 7.3.0` (use [Android Studio - Android Gradle plugin Upgrade Assistant](https://developer.android.com/build/agp-upgrade-assistant) for help), support for `androidx` (see [AndroidX Migration](https://flutter.dev/docs/development/androidx-migration) to migrate an existing app)
- iOS 9.0+: `--ios-language swift`, Xcode version `>= 14.3`

## Installation

Add `bos_gateway_viewer` as a [dependency in your pubspec.yaml file](https://flutter.io/using-packages/).

### Installation - Web support

To make it work properly on the Web platform, you need to add the `web_support.js` file inside the `<head>` of your `web/index.html` file:

```html
<head>
    <!-- ... -->
    <script type="application/javascript" src="/assets/packages/flutter_inappwebview_web/assets/web/web_support.js" defer></script>
    <!-- ... -->
</head>
```  

### Installation - Android support

To make it work properly on the Android platform, you need to add android:usesCleartextTraffic="true" to manifest

### Installation - iOS support

To make it work properly on the iOS platform, you need to add the NSAllowsLocalNetworking key with true in the Info.plist :

```
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```