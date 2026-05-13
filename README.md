# Namaz Reminder

[![GitHub Repo](https://img.shields.io/badge/GitHub-mustafa56969%2FNamaz--Reminder--Custom--Time-blue?style=flat&logo=github)](https://github.com/mustafa56969/Namaz-Reminder-Custom-Time)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0.0+-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/Material-3-6750A4?style=for-the-badge">
</p>

> A beautiful Material 3 prayer reminder app with expressive dynamic themes that automatically adapt throughout the day. Features notes, task reminders, and a stunning UI.

## What It Does

A feature-rich Islamic prayer time reminder application that helps Muslims stay organized with their daily prayers. The app automatically changes its theme based on the time of day - bright and vibrant for morning, warm oranges for Dhuhr, cool blues for Asr, and deep purples for evening. Includes personal notes and task reminder functionality.

### Key Features

| Feature | Description |
|---------|-------------|
| 🕌 **Prayer Times** | Accurate prayer time tracking with customization |
| 🎨 **Dynamic Themes** | Auto-changing themes based on time of day |
| 📝 **Notes Section** | Create and manage personal notes |
| ⏰ **Task Reminders** | Set custom reminders for any task |
| 🌙 **Offline Support** | Works without internet connection |
| 💾 **Local Storage** | SQLite database for persistent data |
| 🔔 **Notifications** | Local notifications for prayer alerts |

### Dynamic Theme System

The app features an intelligent theme system that changes throughout the day:

- **Fajr Morning** - Soft pastel blues and gentle light
- **Dhuhr Noon** - Warm golden yellows and bright whites  
- **Asr Afternoon** - Cool teal and calming greens
- **Maghrib Evening** - Sunset orange and warm pinks
- **Isha Night** - Deep purple and dark blues

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter | UI Framework |
| Provider | State Management |
| SQLite (sqflite) | Local Database |
| flutter_local_notifications | Push Notifications |
| timezone | Prayer Time Calculations |
| google_fonts | Typography |

## Prerequisites

- Flutter SDK 3.0.0+
- Dart SDK 3.0.0+
- Android SDK / Xcode

## Setup

```bash
# Clone the repository
git clone https://github.com/mustafa56969/Namaz-Reminder-Custom-Time.git
cd Namaz-Reminder-Custom-Time

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── models/
│   └── reminder.dart
├── providers/
│   ├── notes_provider.dart
│   ├── prayer_provider.dart
│   ├── reminder_provider.dart
│   └── theme_provider.dart
├── screens/
│   ├── add_note_screen.dart
│   ├── add_reminder_screen.dart
│   ├── home_screen.dart
│   ├── notes_screen.dart
│   ├── permission_screen.dart
│   ├── prayer_screen.dart
│   └── reminders_screen.dart
├── services/
│   └── notification_service.dart
└── widgets/
    └── reminder_card.dart
```

## Building

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web
```

## Permissions

The app requires:
- Notification permissions for prayer alerts
- Storage permissions for local data

## License

Private - All rights reserved