# 🪙 Coin Circle

A modern Flutter-based mobile application for managing group savings pools (chit funds) with a beautiful, intuitive interface.

## 📱 About

Coin Circle is a comprehensive financial management app that allows users to create, join, and manage savings pools with friends, family, or colleagues. The app provides a secure platform for organizing rotating savings and credit associations (ROSCAs) with features like automated winner selection, payment tracking, and real-time notifications.

## ✨ Features

### Core Functionality
- 🏦 **Pool Management**: Create and manage multiple savings pools
- 👥 **Member Management**: Invite and manage pool members
- 💰 **Payment Tracking**: Track contributions and withdrawals
- 🎲 **Winner Selection**: Automated and fair winner selection system
- 📊 **Analytics**: Detailed financial insights and reports
- 🔔 **Notifications**: Real-time updates on pool activities
- 💳 **Wallet Integration**: Built-in wallet for managing funds

### User Experience
- 🎨 Modern, clean UI with smooth animations
- 🌙 Dark mode support
- 📱 Responsive design for all screen sizes
- 🔐 Secure authentication and data encryption
- 🌐 Multi-language support (coming soon)

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider / Riverpod
- **Architecture**: Clean Architecture with feature-first organization
- **Backend**: Firebase (Authentication, Firestore, Cloud Functions)
- **Local Storage**: Hive / Shared Preferences
- **Notifications**: Firebase Cloud Messaging (FCM)

## 📂 Project Structure

```
lib/
├── core/                 # Core utilities, constants, and base classes
├── features/            # Feature modules
│   ├── auth/           # Authentication
│   ├── pools/          # Pool management
│   ├── wallet/         # Wallet & payments
│   ├── notifications/  # Notification system
│   └── profile/        # User profile
├── shared/             # Shared widgets and utilities
└── main.dart           # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/721abhay/coin-circle.git
   cd coin-circle
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update Firebase configuration files

4. **Run the app**
   ```bash
   flutter run
   ```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test
```

## 📦 Build

```bash
# Build APK (Android)
flutter build apk --release

# Build App Bundle (Android)
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Abhay**
- GitHub: [@721abhay](https://github.com/721abhay)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All contributors and testers

---

**Note**: This is an active development project. Features and documentation are continuously being updated.
