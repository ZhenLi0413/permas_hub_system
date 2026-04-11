# Project Setup Guide

This guide explains how to set up `PERMAS_HUB_SYSTEM` with Flutter, GitHub, and a shared Firebase project for the whole team.

## Goal

We will use:

- Flutter as the frontend app and main application logic layer
- Firebase Authentication for login and account management
- Cloud Firestore for shared cloud data
- local device storage for files, cached data, and app-local persistence
- GitHub for source control
- One shared Firebase project for the whole team

We will not use:

- Firebase Storage
- Cloud Functions

## Shared Firebase Approach

For this project, the team should use one shared Firebase project instead of each person creating their own.

Benefits:

- everyone works against the same backend
- no duplicated Firebase setup across teammates
- easier testing for login flows and shared database features
- simpler demo and deployment flow

Recommended project split:

- `permas_hub_system` for development


For now, one shared development Firebase project is enough.

## 1. Install Required Tools

Make sure the main project owner has these installed:

- Flutter SDK
- VS Code
- Git
- Node.js 18 or later
- Firebase CLI
- FlutterFire CLI

Check the versions:

```bash
node -v
flutter --version
git --version
```

Install the Firebase CLI:

```bash
npm install -g firebase-tools
```

Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Verify both tools:

```bash
firebase --version
flutterfire --version
```

## 2. Create or Open the Flutter Project

This repository already contains the Flutter project, so open it in VS Code from the project root:

```bash
code .
```

If the project dependencies are not installed yet:

```bash
flutter pub get
```

## 3. Create the Shared Firebase Project

One team member should create the Firebase project in the Firebase Console.

Recommended steps:

1. Create a new Firebase project.
2. Register the platforms you need.
3. Start with Android, iOS, and Web only if the team plans to use them.
4. Keep this project as the shared development backend.

Good naming example:

- Firebase project name: `permas_hub_system`

## 4. Add Firebase Products

In Firebase Console, enable the services the app will use:

- Authentication
- Cloud Firestore

Do not enable extra Firebase services unless the team actually decides to use them later.

Suggested starter setup:

- Auth: enable Email/Password first
- Firestore: create the database in production mode or test mode, then tighten rules immediately

## 5. Connect Flutter to Firebase

From the project root:

```bash
firebase login
flutterfire configure
```

What this will do:

- link the Flutter app to the shared Firebase project
- register selected platforms
- generate `lib/firebase_options.dart`

This file should stay in source control so teammates can use the same Firebase app configuration.

## 6. Add Firebase Packages

This repository currently does not include Firebase packages yet, so add them when starting the integration:

```bash
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore
```

Use only the packages the project actually needs. For this project, the starting set is:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`

Do not add `firebase_storage` or `cloud_functions` for this project.

## 7. Initialize Firebase in Flutter

Update `lib/main.dart` to initialize Firebase using the generated options file:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

## 8. Architecture Decision

This project keeps most of the application logic inside Flutter.

Use Flutter for:

- form validation
- UI state management
- business rules that do not require a secure backend
- local persistence on the device

Use Firebase only for:

- user authentication
- shared app data stored in Firestore

Use local device storage for:

- temporary files
- app preferences
- cached content
- data that does not need to be shared through Firebase

## 8. Keep Backend Files in the Repository

When Firebase is added, these files should be committed if they exist:

- `lib/firebase_options.dart`
- `firebase.json`
- `.firebaserc` if the team intentionally shares the same Firebase project alias
- Firestore rules files

Do not commit:

- service account JSON files
- private `.env` secrets
- any admin credentials

## 9. Set Security Rules Early

Do not leave Firestore open longer than necessary.

Basic Firestore example:

```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

As the app grows, update rules together with the feature changes.

## 10. Use GitHub as the Source of Truth

Push the project from the start and keep changes small.

Typical workflow:

```bash
git add .
git commit -m "Set up Firebase integration"
git push
```

Push at clear milestones:

- add Firebase core setup
- add authentication
- add Firestore models and services
- update rules

## 11. Local Development Workflow

Recommended terminal usage in VS Code:

- one terminal for `flutter run`
- one terminal for Firebase commands when needed

Useful commands:

```bash
flutter pub get
flutter run
flutter run -d chrome
firebase emulators:start
```

You can use the Firebase Emulator Suite if the team wants local backend testing, but it is optional.

## 12. Deployment Notes

Backend deployment:

```bash
firebase deploy --only firestore
```

If only Firestore rules need to be deployed:

```bash
firebase deploy --only firestore:rules
```

Important:

- this project does not use Firebase Storage
- this project does not use Cloud Functions
- Firebase is only being used for Auth and Firestore
- Android is distributed through APK or AAB
- iOS is distributed through Xcode, TestFlight, or App Store workflows

## Suggested Team Structure

A clean feature structure for this project:

```txt
lib/
  features/
    auth/
    profile/
    chat/
  services/
  models/
  local/
```

Suggested backend mapping:

- Auth for login, registration, logout, and forgot password
- Firestore for user profiles and shared app content
- local storage for cached values, draft data, and device-only files
- Flutter code for the main business logic

## Recommended First Milestone

For the first working version of this project:

1. connect Flutter to the shared Firebase project
2. add `firebase_core`, `firebase_auth`, and `cloud_firestore`
3. enable Auth and Firestore in Firebase Console
4. set up local device storage in Flutter for non-cloud data
5. commit the generated config and rules files
6. push everything to GitHub so teammates can onboard from the same setup
