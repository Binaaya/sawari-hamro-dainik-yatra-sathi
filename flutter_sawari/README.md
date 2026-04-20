# Sawari - Flutter App

A Flutter mobile application for digital transit payments, converted from the original React/Figma design.

## Features

- 🔐 **Authentication**: Login and Registration screens with form validation
- 🏠 **Home Screen**: Token balance display, quick actions, and recent trips
- 🗺️ **Routes Screen**: Browse and search transit routes with filtering
- 💰 **Transactions**: View payment history with tabs for filtering
- 👤 **Profile**: User profile, stats, settings, and logout

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme/
│   ├── app_colors.dart       # Color definitions (light/dark)
│   ├── app_theme.dart        # Theme configuration
│   └── theme.dart            # Barrel file
├── screens/
│   ├── main_app.dart         # Main scaffold with bottom navigation
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── routes/
│   │   └── routes_screen.dart
│   ├── transactions/
│   │   └── transactions_screen.dart
│   └── profile/
│       └── profile_screen.dart
└── widgets/
    ├── image_with_fallback.dart
    ├── quick_action_card.dart
    ├── recent_trip_card.dart
    ├── token_balance_card.dart
    └── widgets.dart          # Barrel file
```

## Getting Started

1. **Ensure Flutter is installed**

   ```bash
   flutter doctor
   ```

2. **Navigate to the project**

   ```bash
   cd flutter_sawari
   ```

3. **Get dependencies**

   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Design Mapping (React → Flutter)

| React Component         | Flutter Equivalent                               |
| ----------------------- | ------------------------------------------------ |
| `App.tsx`               | `main.dart` + `main_app.dart`                    |
| `Login.tsx`             | `screens/auth/login_screen.dart`                 |
| `Register.tsx`          | `screens/auth/register_screen.dart`              |
| `Home.tsx`              | `screens/home/home_screen.dart`                  |
| `Routes.tsx`            | `screens/routes/routes_screen.dart`              |
| `Transactions.tsx`      | `screens/transactions/transactions_screen.dart`  |
| `Profile.tsx`           | `screens/profile/profile_screen.dart`            |
| `ImageWithFallback.tsx` | `widgets/image_with_fallback.dart`               |
| `globals.css`           | `theme/app_colors.dart` + `theme/app_theme.dart` |

## Theme

The app supports both **light** and **dark** themes automatically based on system settings. Colors are defined in `app_colors.dart` and mirror the CSS variables from the original design.

## TODO

- [ ] Connect to backend API
- [ ] Implement QR code scanning
- [ ] Add token top-up functionality
- [ ] Implement route details page
- [ ] Add push notifications
- [ ] Integrate maps for route visualization
