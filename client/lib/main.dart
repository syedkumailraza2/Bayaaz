import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/kalaam_provider.dart';
import 'providers/practice_provider.dart';
import 'providers/group_provider.dart';
import 'providers/session_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_kalaam_screen.dart';
import 'screens/kalaam_detail_screen.dart';
import 'screens/majlis_screen.dart';
import 'screens/practice_mode_screen.dart';
import 'screens/search_screen.dart';
import 'screens/group_detail_screen.dart';
import 'screens/group_session_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KalaamProvider()),
        ChangeNotifierProvider(create: (_) => PracticeProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: const BayaazApp(),
    ),
  );
}

class BayaazApp extends StatelessWidget {
  const BayaazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bayaaz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFe2b96f),
          surface: Color(0xFF1a1a2e),
        ),
        scaffoldBackgroundColor: const Color(0xFF0f0f1a),
      ),
      home: const _SplashRouter(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/add': (_) => const AddKalaamScreen(),
        '/kalaam': (_) => const KalaamDetailScreen(),
        '/majlis': (_) => const MajlisScreen(),
        '/practice': (_) => const PracticeModeScreen(),
        '/search': (_) => const SearchScreen(),
        '/group': (_) => const GroupDetailScreen(),
        '/session': (_) => const GroupSessionScreen(),
      },
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await context.read<AuthProvider>().tryAutoLogin();
    if (!mounted) return;
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    Navigator.pushReplacementNamed(context, isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0f0f1a),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories, size: 60, color: Color(0xFFe2b96f)),
            SizedBox(height: 16),
            Text(
              'بیاض',
              style: TextStyle(fontSize: 36, color: Color(0xFFe2b96f), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
