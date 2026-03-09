# my_flutter_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

- `flutter pub get`
- `flutter run` or `flutter run -d chrome --web-experimental-hot-reload`
- `brew services start mongodb/brew/mongodb-community@7.0`
- `mongosh`

## Run on iOS

- Download and install Xcode from the App Store
- Open Xcode and install additional components
- Create a certificate for development
- Open terminal and run:
        - `brew install cocoapods`
        - `flutter clean`
        - `flutter pub get`
        - `cd ios`
        - `pod install`
        - `cd ..`
        - `flutter run`
