# BookShelf

BookShelf is a Flutter Android app that gives each signed-in user a private,
persistent library backed by Firebase Authentication and Cloud Firestore.

## Student

- Student code: QE190072
- Full name: Phan Chi Thong
- Firebase project: `bookshelf-qe190072`

## Features

- Email/password registration and login with the required validation messages
- Private per-user books protected by Firestore Security Rules
- Add, edit, delete, favorite, rate, and annotate books
- Combined genre, status, favorites, and text filters
- Live counts and status summary for the currently visible books
- Responsive Material 3 interface with light and dark themes

## Run

```text
flutter pub get
flutter run
```

The Android client Firebase configuration is included. No admin or service
account credentials are used.

## Test and build

```text
flutter analyze
flutter test
flutter build apk --release
```

The release APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.
