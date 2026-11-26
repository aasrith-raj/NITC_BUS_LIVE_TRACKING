# NITC Campus Bus Tracking – Flutter frontend starter

## Included
- Role-selection demo login (not real authentication)
- Student dashboard with OpenStreetMap and bus list API call
- Driver dashboard with one-time location permission/location retrieval
- Administrator dashboard entry points
- API service scaffold
- Bus model

## Setup
1. Install Flutter SDK and Android Studio.
2. Extract this project.
3. Open a terminal in this folder.
4. Run:
   ```bash
   flutter create .
   flutter pub get
   flutter run
   ```

## Backend URL
Edit `lib/services/api_service.dart`.

- Android emulator: `http://10.0.2.2:8000`
- Physical phone: `http://YOUR_COMPUTER_LAN_IP:8000`
- Production: use your HTTPS backend URL.

The sample `GET /buses/` parser expects each bus JSON object to include:
`bus_id`, `bus_number`, `status`, and optionally `latitude`, `longitude`,
`route_name`, `last_updated`.

The sample location POST uses `/locations/` and sends latitude/longitude.
Adjust it to match your actual FastAPI request schema and endpoint.

## Important
The login is a UI-only role selector. It does not authenticate users.
The driver screen retrieves a location once; it does not continuously upload GPS.
Admin management cards are UI placeholders. These must be connected to secured
FastAPI endpoints before real deployment.

OpenStreetMap requires visible attribution. Follow the tile usage policy:
https://operations.osmfoundation.org/policies/tiles/

Never commit passwords, JWT secrets, or production API credentials to Git.
# NITC Campus Bus Tracking System – Frontend

A Flutter-based mobile application developed for the NIT Calicut Campus Bus Tracking System.

## Features

- User registration and login
- Role-based dashboards for Students, Staff, Drivers, and Administrators
- Bus management
- Route and stop management
- Bus tracking and location sharing
- Estimated Time of Arrival (ETA) functionality
- User management for administrators

## Technology Stack

- Flutter
- Dart
- Android SDK
- REST API integration
- MySQL-backed FastAPI backend

## Requirements

- Flutter SDK
- Dart SDK
- Android Studio or Android SDK
- Android Emulator or Android device
- Git

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/nitc-bus-tracking-frontend.git
cd nitc-bus-tracking-frontend
```

Install dependencies:

```bash
flutter pub get
```

## Backend Configuration

Configure the API base URL in the API service file.

For Android Emulator:

```text
http://10.0.2.2:8000
```

For a physical Android device, use your computer's local network IP address.

Ensure that the backend is running before using the application.

## Run the Application

```bash
flutter run
```

To run on a specific emulator:

```bash
flutter run -d emulator-5554
```

## Build APK

```bash
flutter build apk --release
```

## Project Structure

```text
lib/
  main.dart
  models/
  screens/
  services/
  widgets/

android/
assets/
test/
pubspec.yaml
```

## Backend Repository

The corresponding backend is maintained separately in the `nitc-bus-tracking-backend` repository.

## Contributors

| S. No. | Name | Roll Number |
|---|---|---|
| 1 | Aasrith Raj | M260774CS |
| 2 | Vinay Kumar Guddati | M261191CS |
| 3 | Shruti | M260997CS |




