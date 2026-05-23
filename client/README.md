# Client

This directory holds the Flutter frontend for the BridgeLink logistics app.

## Getting Started

1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. Run from the client folder:
   ```powershell
   flutter pub get
   flutter run
   ```

## Structure
- `lib/main.dart` — app entry point
- `lib/src/app.dart` — router and app shell
- `lib/src/screens/` — customer and admin screens
- `lib/src/widgets/` — shared responsive layout widgets
- `lib/src/models/` — data models

## Notes
- The current scaffold includes customer home and admin dashboard shells.
- Next step: connect screens to backend APIs and add authentication, catalog, cart, and order flows.
