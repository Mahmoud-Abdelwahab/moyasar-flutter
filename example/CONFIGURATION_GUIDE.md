# Example App Configuration Guide

## Bundle ID / Application ID for Apple Pay & Samsung Pay

The example app supports **two Android flavors**. iOS uses a single bundle ID (no flavors).

### Important: Apple Pay (iOS) Still Works

**iOS bundle ID was NOT changed.** It remains `com.moyasar.coffeeFlutterVeryUnique` (configured for Apple Pay). To run on iOS:

```bash
flutter run --flavor default_
```

Or target iOS explicitly:

```bash
flutter run --flavor default_ -d <ios-device-id>
```

### Option 1: Apple Pay on iOS (Default Flavor)

| Platform | Bundle/Application ID |
|----------|------------------------|
| iOS      | `com.moyasar.coffeeFlutterVeryUnique` (Apple Pay enabled) |
| Android  | `com.example.coffee_flutter` |

```bash
flutter run --flavor default_
```

### Option 2: Samsung Pay Demo on Android (Spay Flavor)

| Platform | Bundle/Application ID |
|----------|------------------------|
| Android  | `com.mysr.spay` (Samsung test service registered) |

```bash
flutter run --flavor spay
```

Use a Samsung Android device; the Samsung Pay button appears when the SDK is ready.

### Option 3: Production – Same Bundle for Both

For your own app, use **one bundle identifier** across platforms:

1. **Choose your bundle ID** (e.g. `com.yourcompany.yourapp`)
2. **iOS**: Set `PRODUCT_BUNDLE_IDENTIFIER` in Xcode to your bundle ID
3. **Android**: Set `applicationId` in `build.gradle` (default_ flavor) to the same value
4. **Apple Pay**: Register your App ID with Apple Pay in [Apple Developer Portal](https://developer.apple.com)
5. **Samsung Pay**: Register your package name in [Samsung Pay Developer Portal](https://pay.samsung.com/developer)

### Quick Reference

| Platform | default_ (Apple Pay)        | spay (Samsung Pay Demo) |
|----------|-----------------------------|--------------------------|
| Android  | com.example.coffee_flutter  | com.mysr.spay            |
| iOS      | com.moyasar.coffeeFlutterVeryUnique | *(iOS has no flavors; always uses this)* |

### If iOS / Apple Pay Stopped Working

1. **Confirm bundle ID** in Xcode: `Runner` → Target → General → Bundle Identifier = `com.moyasar.coffeeFlutterVeryUnique`
2. **Run with default flavor**: `flutter run --flavor default_` (required when Android has product flavors)
3. **Apple Pay capability**: Ensure the App ID has Apple Pay enabled and the correct merchant ID in Apple Developer
4. **Entitlements**: `Runner.entitlements` should include your Apple Pay merchant ID
