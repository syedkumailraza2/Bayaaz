# 🚀 Bayaaz Setup Guide

This guide will help you set up the complete Bayaaz application on your local development machine.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required Software
- **Node.js** (v16 or higher) - [Download here](https://nodejs.org/)
- **npm** (comes with Node.js)
- **Flutter** (v3.x) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **MongoDB** (v4.4 or higher) - [Download here](https://www.mongodb.com/try/download/community)
- **Git** - [Download here](https://git-scm.com/)

### Development Tools (Recommended)
- **VS Code** with extensions:
  - Flutter
  - Dart
  - MongoDB for VS Code
  - Thunder Client (for API testing)

### Cloud Services (Required for full functionality)
- **Cloudinary account** - [Sign up free](https://cloudinary.com/)

---

## 🗂️ Project Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Bayaaz
```

### 2. Backend Setup

Navigate to the backend directory:

```bash
cd backend
```

#### Install Dependencies
```bash
npm install
```

#### Environment Configuration
1. Copy the environment template:
```bash
cp .env.example .env
```

2. Open `.env` file and configure the following:

```env
# Server Configuration
PORT=5000
NODE_ENV=development

# MongoDB (required)
MONGODB_URI=mongodb://localhost:27017/bayaaz

# JWT (required)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=7d

# Cloudinary (required for file uploads)
CLOUDINARY_CLOUD_NAME=your-cloudinary-cloud-name
CLOUDINARY_API_KEY=your-cloudinary-api-key
CLOUDINARY_API_SECRET=your-cloudinary-api-secret

# Frontend URL
FRONTEND_URL=http://localhost:3000
```

#### Getting Cloudinary Credentials
1. Sign up at [Cloudinary](https://cloudinary.com/)
2. Go to Dashboard → API Security
3. Copy your Cloud Name, API Key, and API Secret
4. Add them to your `.env` file

#### Start MongoDB
Make sure MongoDB is running on your system:

**Windows:**
```bash
# If installed as service
net start MongoDB

# Or run manually
"C:\Program Files\MongoDB\Server\X.X\bin\mongod.exe"
```

**macOS:**
```bash
# If installed with Homebrew
brew services start mongodb-community

# Or run manually
mongod
```

**Linux:**
```bash
# If installed with package manager
sudo systemctl start mongod

# Or run manually
mongod
```

#### Start Backend Server
```bash
# Development mode (with auto-restart)
npm run dev

# Or production mode
npm start
```

The backend should now be running at `http://localhost:5000`

### 3. Flutter Frontend Setup

Navigate to the Flutter directory:

```bash
cd ../bayaaz
```

#### Install Dependencies
```bash
flutter pub get
```

#### Generate Hive Adapters
Hive requires code generation for type adapters:

```bash
flutter packages pub run build_runner build
```

If you get any errors, try:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### Verify Setup
Check if everything is installed correctly:

```bash
flutter doctor
```

You should see all items checked with ✅

#### Run the App
```bash
# Run on connected device/emulator
flutter run

# Or run on specific platform
flutter run -d chrome        # Web
flutter run -d windows       # Windows
flutter run -d macos         # macOS
flutter run -d android       # Android
flutter run -d ios           # iOS
```

---

## ✅ Verification Steps

### 1. Test Backend API

Open your browser or API client and test:

**Health Check:**
```
GET http://localhost:5000/api/health
```
Should return:
```json
{
  "status": "OK",
  "timestamp": "2023-XX-XX..."
}
```

**Register New User:**
```
POST http://localhost:5000/api/auth/register
Content-Type: application/json

{
  "username": "testuser",
  "email": "test@example.com",
  "password": "Test123456",
  "firstName": "Test",
  "lastName": "User"
}
```

### 2. Test Flutter App

1. Launch the Flutter app
2. You should see the Bayaaz login screen
3. Try registering a new account
4. Verify you can login successfully
5. Check if you can see the default categories

### 3. Test File Upload

1. Try creating a new lyric
2. Test adding an image attachment
3. Check if the file appears in your Cloudinary dashboard

---

## 🔧 Common Issues & Solutions

### Backend Issues

**MongoDB Connection Error:**
```
Error: connect ECONNREFUSED 127.0.0.1:27017
```
**Solution:** Make sure MongoDB is running. Check if it's installed and started.

**JWT Secret Error:**
```
JsonWebTokenError: invalid signature
```
**Solution:** Ensure JWT_SECRET is set in your `.env` file and the app is restarted.

**Cloudinary Upload Error:**
```
Error: Cloudinary API requires credentials
```
**Solution:** Verify all Cloudinary credentials are correctly set in `.env`.

### Flutter Issues

**Hive Generation Error:**
```
Could not find generator for type X
```
**Solution:** Run `flutter packages pub run build_runner clean` then regenerate.

**Font Loading Error:**
```
Failed to load font family
```
**Solution:** Run `flutter pub get` and restart the app.

**Network Error:**
```
SocketException: Connection refused
```
**Solution:** Make sure the backend server is running on port 5000.

### Android-Specific Issues

**Gradle Build Failed:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

**Manifest Merger Failed:**
Add these permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS-Specific Issues

**Xcode Build Failed:**
```bash
cd ios
pod install
cd ..
flutter clean
flutter run
```

Add these permissions to `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to upload images</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone to record audio</string>
```

---

## 🎯 Development Workflow

### 1. Making Changes
- **Backend Changes:** Restart the server after changing `.env` or server files
- **Flutter Changes:** Hot reload works for most UI changes
- **Model Changes:** Regenerate Hive adapters after changing models

### 2. Testing Your Changes
```bash
# Backend tests
cd backend
npm test

# Flutter tests
cd bayaaz
flutter test

# Run with coverage
flutter test --coverage
```

### 3. Debugging
- **Backend:** Check console output and use browser dev tools
- **Flutter:** Use Flutter Inspector in VS Code or Android Studio

---

## 🚀 Production Deployment

### Backend (Server)

1. Set production environment variables
2. Install PM2 process manager:
```bash
npm install -g pm2
```

3. Start production server:
```bash
pm2 start server.js --name bayaaz-api
pm2 save
pm2 startup
```

### Flutter (Mobile App)

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
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

---

## 📞 Need Help?

If you're still having issues:

1. Check the [GitHub Issues](../../issues) page
2. Search for similar problems
3. Create a new issue with:
   - Your operating system
   - Error messages
   - Steps to reproduce
   - Screenshots if applicable

Happy coding! 🎉