# CarWash Pro

A comprehensive Flutter-based mobile application for booking and managing car wash services. The app connects customers with professional car washers, enabling seamless booking, real-time tracking, and secure payment processing.

## 🚗 Features

### For Customers
- **User Authentication**: Secure login, registration, and password recovery
- **Service Browsing**: Browse available car wash services with detailed information
- **Easy Booking**: Multi-step booking process with service selection, date/time picker, and location selection
- **Real-Time Tracking**: Live tracking of washer location and booking status updates
- **Payment Processing**: Secure payment integration for booking transactions
- **Booking Management**: View, manage, and cancel bookings with status tracking
- **Profile Management**: Edit profile information and manage account settings
- **Booking History**: Access complete history of past and current bookings

### For Washers
- **Washer Dashboard**: View available bookings and manage assigned jobs
- **Booking Acceptance**: Accept or decline booking requests
- **Status Updates**: Update booking status (in-progress, completed, etc.)
- **Booking Details**: View detailed information about each booking
- **History Tracking**: Access complete history of completed bookings
- **Profile Management**: Manage washer profile and settings

### For Administrators
- **Admin Dashboard**: Comprehensive overview of system operations
- **User Management**: Manage customer and washer accounts
- **Booking Management**: Monitor and manage all bookings across the platform
- **Service Management**: Add, edit, and manage car wash services
- **Analytics & Statistics**: View platform statistics and performance metrics

## 🛠️ Tech Stack

### Core Technologies
- **Flutter**: Cross-platform mobile development framework
- **Dart**: Programming language (SDK ^3.10.0)

### State Management
- **Provider**: State management solution
- **Riverpod**: Advanced state management with compile-time safety

### Networking & API
- **Dio**: HTTP client for API communication
- **WebSocket**: Real-time communication for live tracking and updates

### Routing & Navigation
- **GoRouter**: Declarative routing solution with deep linking support

### Location Services
- **Geolocator**: Location services and GPS functionality
- **Geocoding**: Address geocoding and reverse geocoding
- **Flutter Map**: Interactive map display with custom markers

### Storage
- **Shared Preferences**: Local data persistence
- **Flutter Secure Storage**: Secure storage for sensitive data (tokens, credentials)

### Notifications
- **Flutter Local Notifications**: Local push notifications for booking updates

### Utilities
- **Image Picker**: Camera and gallery image selection
- **URL Launcher**: Open external links and make phone calls
- **Intl**: Internationalization and date formatting
- **Equatable**: Value equality comparisons
- **Freezed**: Code generation for immutable classes
- **JSON Serializable**: JSON serialization code generation

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.10.0 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd car_wash
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run code generation** (if using generated code)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure API endpoints**
   - Update `lib/core/constants/api_constants.dart` with your backend API URL
   - Configure WebSocket URL if using real-time features

5. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production

**Android:**
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

## 📁 Project Structure

```
lib/
├── app.dart                    # Main app widget with providers
├── main.dart                   # App entry point
├── core/                       # Core functionality
│   ├── constants/             # App constants (API, routes, etc.)
│   ├── models/                # Data models
│   ├── network/               # API client and network configuration
│   ├── storage/               # Local storage utilities
│   ├── theme/                 # App theming and colors
│   └── utils/                 # Utility functions
├── features/                   # Feature modules
│   ├── admin/                 # Admin dashboard and management
│   ├── auth/                  # Authentication (login, register)
│   ├── bookings/              # Booking management
│   ├── home/                  # Home screen
│   ├── location/              # Location services
│   ├── payments/              # Payment processing
│   ├── profile/               # User profile management
│   ├── services/              # Car wash services
│   └── washer/                # Washer-specific features
├── routes/                     # App routing configuration
│   ├── app_router.dart        # Route definitions
│   └── route_guards.dart      # Route protection and guards
└── shared/                     # Shared components
    ├── services/              # Shared services (notifications, etc.)
    └── widgets/               # Reusable widgets
```

## 🔐 Authentication & Security

- JWT-based authentication with token refresh
- Secure storage for sensitive data
- Route guards for protected pages
- Role-based access control (Customer, Washer, Admin)

## 📡 API Integration

The app communicates with a RESTful backend API. Key endpoints include:

- **Authentication**: `/auth/login`, `/auth/register`, `/auth/refresh`
- **Users**: `/users/me`, `/users/profile`
- **Services**: `/services`, `/services/{id}`
- **Bookings**: `/bookings`, `/bookings/{id}`, `/bookings/{id}/cancel`
- **Payments**: `/payments`, `/payments/process`
- **Washer**: `/bookings/available`, `/bookings/{id}/accept`
- **Admin**: `/admin/users`, `/admin/bookings`, `/admin/stats`

API base URL and endpoints are configured in `lib/core/constants/api_constants.dart`.

## 🎨 Theming

The app supports light and dark themes with customizable colors defined in `lib/core/theme/`. Theme configuration can be found in `app_theme.dart`.

## 📝 Development

### Code Generation
When using Freezed or JSON Serializable, run:
```bash
flutter pub run build_runner watch
```

### Testing
```bash
flutter test
```

### Linting
The project uses `flutter_lints` for code quality. Lint rules are configured in `analysis_options.yaml`.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is private and not intended for public distribution.

## 👥 Support

For support, email [your-email] or create an issue in the repository.

---

**Built with ❤️ using Flutter**
