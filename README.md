# Aura

Aura is a Flutter mobile app that provides a secure, AI-powered medical assistant experience. The app stores chat history per authenticated user and supports managing multiple conversations while offering a polished, clinical interface.

## Key Features

- Secure user authentication with Firebase
- Saved medical chat sessions per user
- Conversation switching and history management
- AI-driven symptom diagnosis and health guidance
- Responsive Flutter UI with a glassmorphism-inspired design

## Project Structure

- `lib/main.dart` — app entry point
- `lib/views/` — screen and UI widgets
- `lib/viewmodel/` — app state and business logic
- `lib/services/` — Firebase and auth integrations
- `lib/models/` — domain models for chat and messages
- `lib/theme/` — shared theme and styling utilities

## Setup

1. Install Flutter and required tools
   - See the official docs: https://docs.flutter.dev/get-started/install

2. Get project dependencies

```bash
flutter pub get
```

3. Configure Firebase

- Add your `google-services.json` to `android/app`
- Add your `GoogleService-Info.plist` to `ios/Runner`
- Verify `firebase_options.dart` is generated and correct

4. Run the app

```bash
flutter run
```

## Notes

- Use a hot restart after modifying provider setup or Firebase configuration.
- If the app freezes when opening a conversation dropdown or bottom sheet, the issue is usually related to provider scoping. Make sure the `ChatViewModel` is available in the current widget tree.

## Contributing

Feel free to open issues or submit pull requests for enhancements, bug fixes, and UI improvements.

## License

This project is currently unpublished. Update this section with the correct license information if needed.

