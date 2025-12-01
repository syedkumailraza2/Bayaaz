class AppConstants {
  // App Info
  static const String appName = 'Bayaaz';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'http://192.168.11.115:5000/api';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String fontSizeKey = 'font_size';
  static const String lastSyncKey = 'last_sync_time';

  // Default Categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Nauha', 'color': '#1f2937', 'icon': 'heart'},
    {'name': 'Salaam', 'color': '#059669', 'icon': 'pray'},
    {'name': 'Manqabat', 'color': '#7c3aed', 'icon': 'star'},
    {'name': 'Marsiya', 'color': '#dc2626', 'icon': 'cloud'},
    {'name': 'Qasida', 'color': '#ea580c', 'icon': 'scroll'},
    {'name': 'Poetry', 'color': '#0891b2', 'icon': 'feather'},
  ];

  // Theme Colors
  static const Map<String, String> themeColors = {
    'primary': '#6366f1',
    'secondary': '#8b5cf6',
    'success': '#10b981',
    'warning': '#f59e0b',
    'error': '#ef4444',
    'info': '#3b82f6',
  };

  // Pagination
  static const int defaultPageSize = 20;
  static const int searchPageSize = 50;

  // File Upload Limits
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxAudioSize = 50 * 1024 * 1024; // 50MB
  static const int maxDocumentSize = 20 * 1024 * 1024; // 20MB
  static const int maxImagesAtOnce = 5;

  // Text Limits
  static const int maxTitleLength = 200;
  static const int maxPoetLength = 100;
  static const int maxDescriptionLength = 200;
  static const int maxBioLength = 500;
  static const int maxTagLength = 50;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Debounce Times
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration autoSaveDebounce = Duration(milliseconds: 1000);

  // Cache Configuration
  static const Duration imageCacheDuration = Duration(days: 30);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Network Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Security
  static const int minPasswordLength = 6;
  static const int sessionTimeoutHours = 24;

  // Export Formats
  static const List<String> supportedExportFormats = ['json', 'pdf'];

  // Supported Languages
  static const List<String> supportedLanguages = [
    'urdu', 'arabic', 'persian', 'english', 'hindi', 'other'
  ];

  // Regex Patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String passwordPattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)';
  static const String usernamePattern = r'^[a-zA-Z0-9_]+$';

  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection';
  static const String serverErrorMessage = 'Something went wrong. Please try again';
  static const String authErrorMessage = 'Please login to continue';
  static const String genericErrorMessage = 'An unexpected error occurred';

  // Success Messages
  static const String saveSuccessMessage = 'Saved successfully';
  static const String deleteSuccessMessage = 'Deleted successfully';
  static const String updateSuccessMessage = 'Updated successfully';
  static const String loginSuccessMessage = 'Login successful';
  static const String registerSuccessMessage = 'Registration successful';

  // Local Storage Box Names
  static const String userBox = 'userBox';
  static const String lyricBox = 'lyricBox';
  static const String categoryBox = 'categoryBox';
  static const String settingsBox = 'settingsBox';
  static const String syncBox = 'syncBox';
}