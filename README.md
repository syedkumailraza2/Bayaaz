# Bayaaz - Your Digital Poetry Diary 📚

A beautiful mobile app for storing Nauha, Salaam, Manqabat, Marsiya, and other religious poetry and lyrical content. Built with Flutter frontend and Node.js backend.

## 📱 Features

### ✨ Core Features
- **Offline-First**: Store lyrics locally with automatic cloud sync
- **Rich Text Editor**: Format your poetry with beautiful typography
- **Categorization**: Organize by Nauha, Salaam, Manqabat, Marsiya, Qasida, Poetry
- **Smart Search**: Search by title, poet, tags, or content
- **Favorites & Pinning**: Mark important lyrics and pin them to the top
- **Audio & Image Attachments**: Attach reference tunes and scanned pages

### 🎯 Advanced Features
- **Cloud Sync**: Automatic sync when online
- **Version History**: Track and restore previous edits
- **Export/Import**: Backup your data as JSON or PDF
- **Dark Mode**: Beautiful light and dark themes
- **Multi-Device Sync**: Access your poetry from any device
- **Secure Vault**: Lock sensitive lyrics with PIN/biometric
- **Share Features**: Share as text or beautiful image cards

## 🏗️ Tech Stack

### Frontend (Flutter)
- Flutter 3.x
- Provider State Management
- Hive (Local Database)
- Material Design 3
- Google Fonts

### Backend (Node.js)
- Node.js + Express
- MongoDB with Mongoose
- JWT Authentication
- Multer + Cloudinary (File Uploads)
- Comprehensive API with validation

## 🚀 Quick Start

### Prerequisites
- Node.js 16+ and npm
- Flutter 3.x
- MongoDB
- Cloudinary account (for file uploads)

### Backend Setup

1. **Clone and Navigate**
```bash
git clone <repository-url>
cd Bayaaz/backend
```

2. **Install Dependencies**
```bash
npm install
```

3. **Environment Configuration**
```bash
cp .env.example .env
```

Edit `.env` with your configuration:
```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/bayaaz
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=7d
CLOUDINARY_CLOUD_NAME=your-cloudinary-cloud-name
CLOUDINARY_API_KEY=your-cloudinary-api-key
CLOUDINARY_API_SECRET=your-cloudinary-api-secret
FRONTEND_URL=http://localhost:3000
```

4. **Start MongoDB**
```bash
# Make sure MongoDB is running
mongod
```

5. **Run Development Server**
```bash
npm run dev
```

Backend will be running at `http://localhost:5000`

### Frontend Setup

1. **Navigate to Flutter Directory**
```bash
cd ../bayaaz
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Generate Hive Adapters**
```bash
flutter packages pub run build_runner build
```

4. **Run the App**
```bash
flutter run
```

## 📁 Project Structure

```
Bayaaz/
├── backend/                 # Node.js Backend
│   ├── controllers/         # Route controllers
│   ├── middleware/          # Authentication & validation
│   ├── models/             # MongoDB models
│   ├── routes/             # API routes
│   ├── services/           # Business logic
│   ├── utils/              # Helper functions
│   ├── server.js           # Main server file
│   └── package.json
│
└── bayaaz/                 # Flutter Frontend
    ├── lib/
    │   ├── constants/      # App constants
    │   ├── models/         # Data models
    │   ├── providers/      # State management
    │   ├── screens/        # UI screens
    │   ├── services/       # API and storage services
    │   ├── themes/         # App themes
    │   ├── utils/          # Helper functions
    │   ├── widgets/        # Reusable widgets
    │   └── main.dart       # App entry point
    ├── pubspec.yaml
    └── README.md
```

## 🔧 Development Guide

### Backend API Endpoints

#### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update profile
- `POST /api/auth/change-password` - Change password

#### Lyrics
- `GET /api/lyrics` - Get user's lyrics (with pagination/filters)
- `POST /api/lyrics` - Create new lyric
- `GET /api/lyrics/:id` - Get single lyric
- `PUT /api/lyrics/:id` - Update lyric
- `DELETE /api/lyrics/:id` - Delete lyric
- `POST /api/lyrics/:id/favorite` - Toggle favorite
- `POST /api/lyrics/:id/pin` - Toggle pin

#### Categories
- `GET /api/categories` - Get user's categories
- `POST /api/categories` - Create new category
- `PUT /api/categories/:id` - Update category
- `DELETE /api/categories/:id` - Delete category

#### File Upload
- `POST /api/upload/images` - Upload images
- `POST /api/upload/audio` - Upload audio files
- `POST /api/upload/documents` - Upload documents

### Flutter Architecture

The Flutter app follows a clean architecture pattern:

- **Models**: Data classes with JSON serialization
- **Providers**: State management using Provider pattern
- **Services**: API calls and local storage
- **Screens**: UI screens for different features
- **Widgets**: Reusable UI components

## 🎨 UI/UX Features

### Themes
- Light theme with beautiful colors
- Dark mode support
- Custom font sizes
- Material Design 3

### Navigation
- Bottom navigation bar
- Smooth transitions
- Intuitive user flow
- Loading states and error handling

### Responsive Design
- Works on all screen sizes
- Adaptive layouts
- Touch-friendly interface

## 🔒 Security Features

- JWT-based authentication
- Password encryption with bcrypt
- Request rate limiting
- Input validation and sanitization
- Secure file uploads with Cloudinary

## 📱 Platform Support

- **Android**: API 21+ (Android 5.0)
- **iOS**: iOS 11.0+
- **Web**: Chrome, Safari, Firefox, Edge

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm test
```

### Flutter Tests
```bash
cd bayaaz
flutter test
```

## 📦 Deployment

### Backend Deployment (Production)
1. Set production environment variables
2. Install PM2: `npm install -g pm2`
3. Start with PM2: `pm2 start server.js --name bayaaz-api`

### Flutter App Deployment
1. **Android**:
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```

2. **iOS**:
   ```bash
   flutter build ios --release
   ```

3. **Web**:
   ```bash
   flutter build web --release
   ```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues:

1. Check the [Issues](../../issues) page
2. Create a new issue with detailed information
3. Include screenshots if applicable
4. Mention your platform and app version

## 🌟 Acknowledgments

- Flutter team for the amazing framework
- Material Design for UI guidelines
- All contributors who help improve this project

## 📊 Roadmap

- [ ] Web app version
- [ ] Desktop applications (Windows, macOS, Linux)
- [ ] Real-time collaboration features
- [ ] AI-powered poetry analysis
- [ ] Community features and sharing
- [ ] Premium subscription features
- [ ] Multi-language support

---

Made with ❤️ for the poetry community