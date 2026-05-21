import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'db/isar_service.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/kalaam_provider.dart';
import 'providers/practice_provider.dart';
import 'providers/group_provider.dart';
import 'providers/session_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_kalaam_screen.dart';
import 'screens/kalaam_detail_screen.dart';
import 'screens/practice_mode_screen.dart';
import 'screens/search_screen.dart';
import 'screens/group_detail_screen.dart';
import 'screens/group_session_screen.dart';
import 'screens/group_session_teleprompter.dart';
import 'services/deep_link_service.dart';
import 'services/offline_sync_service.dart';
import 'services/warmup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProxyProvider<ConnectivityProvider, KalaamProvider>(
          create: (_) => KalaamProvider(),
          update: (_, connectivity, provider) {
            final p = provider ?? KalaamProvider();
            p.attachConnectivity(connectivity);
            return p;
          },
        ),
        ChangeNotifierProvider(create: (_) => PracticeProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProxyProvider<ConnectivityProvider, SessionProvider>(
          create: (_) => SessionProvider(),
          update: (_, connectivity, provider) {
            final p = provider ?? SessionProvider();
            p.attachConnectivity(connectivity);
            return p;
          },
        ),
      ],
      child: const BayaazApp(),
    ),
  );
}

/// Top-level navigator key so the deep-link service can push routes from
/// outside a widget context.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class BayaazApp extends StatelessWidget {
  const BayaazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bayaaz',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
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
        '/edit': (_) => const AddKalaamScreen(),
        '/kalaam': (_) => const KalaamDetailScreen(),
        '/practice': (_) => const PracticeModeScreen(),
        '/search': (_) => const SearchScreen(),
        '/group': (_) => const GroupDetailScreen(),
        '/session': (_) => const GroupSessionScreen(),
        '/group-teleprompter': (_) => const GroupSessionTeleprompter(),
      },
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter>
    with SingleTickerProviderStateMixin {
  StreamSubscription<bool>? _connectivitySub;
  late final AnimationController _anim;
  late final Animation<double> _topLine;
  late final Animation<double> _writing;
  late final Animation<double> _subtitle;
  late final Animation<double> _bottomLine;

  // Becomes true once the warmup ping has been slow long enough to warrant
  // showing the user a "Waking up server…" hint. Render cold starts take
  // 30-50s; we don't want to leave the user staring at a frozen splash.
  bool _showColdStartHint = false;
  Timer? _coldStartHintTimer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _topLine = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.0, 0.20, curve: Curves.easeOut),
    );
    // The writing reveal — uses easeInOut so the "pen" accelerates then
    // settles, mimicking a calligrapher's hand.
    _writing = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.15, 0.78, curve: Curves.easeInOutCubic),
    );
    _subtitle = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.78, 0.92, curve: Curves.easeOut),
    );
    _bottomLine = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
    );
    _anim.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Keep the splash up for the full writing sequence even on instant boots.
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 2600));

    // Kick off the server warmup ping in parallel with local boot work.
    // Render's free tier cold-starts in 30-50s; the rest of the bootstrap
    // (Isar open, cache hydrate) is local and fast, so we'd otherwise sit on
    // the home screen and have the first real request fail with a timeout.
    final warmup = WarmupService.instance.warmup(
      maxTotalDuration: const Duration(seconds: 60),
    );
    // If the server doesn't come back within 2.5s, show the user a "waking up"
    // hint so the long splash doesn't look like a hang.
    _coldStartHintTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && !WarmupService.instance.isWarm) {
        setState(() => _showColdStartHint = true);
      }
    });

    // 1. Open Isar before anything reads/writes the cache.
    try {
      await IsarService.instance.open();
    } catch (_) {
      // App can still run without offline cache; continue.
    }

    if (!mounted) return;

    // 2. Hydrate every cache-backed list so each tab paints instantly.
    final kalaamProvider = context.read<KalaamProvider>();
    if (IsarService.instance.isOpen) {
      await kalaamProvider.hydrateFeedFromCache();
      await kalaamProvider.hydrateMyBayaazFromCache();
    }

    if (!mounted) return;

    // 2b. Wait for the server to be warm before doing any network work.
    // tryAutoLogin and the post-login syncs all need a live backend; firing
    // them at a cold dyno fails fast and leaves the app in a bad state.
    await warmup;
    _coldStartHintTimer?.cancel();
    if (mounted && _showColdStartHint) {
      setState(() => _showColdStartHint = false);
    }

    if (!mounted) return;

    // 3. Resolve auth.
    await context.read<AuthProvider>().tryAutoLogin();

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final connectivity = context.read<ConnectivityProvider>();

    // 4. Fire-and-forget background sync if logged in & online.
    if (auth.isLoggedIn && connectivity.isOnline && IsarService.instance.isOpen) {
      unawaited(OfflineSyncService.instance.syncAll());
    }

    // 5. Subscribe to offline→online transitions for future re-syncs.
    _connectivitySub = connectivity.onChange.listen((online) {
      if (online && auth.isLoggedIn && IsarService.instance.isOpen) {
        unawaited(OfflineSyncService.instance.syncAll());
        unawaited(OfflineSyncService.instance.drainPendingSessionOps());
      }
    });

    // 6. Start the deep-link listener. It will navigate on incoming links;
    //    if user is logged out, it stashes the token for post-login redemption.
    await DeepLinkService.instance.init(
      navigatorKey: rootNavigatorKey,
      isLoggedIn: () => auth.isLoggedIn,
    );

    await minSplash;
    if (!mounted) return;

    // 7. Route to home or login.
    Navigator.pushReplacementNamed(context, auth.isLoggedIn ? '/home' : '/login');

    // 8. If we landed at home with a stashed invite token, redeem it now.
    if (auth.isLoggedIn) {
      unawaited(DeepLinkService.instance.consumePendingToken());
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _connectivitySub?.cancel();
    _coldStartHintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFe2b96f);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [Color(0xFF1a1a2e), Color(0xFF0f0f1a)],
          ),
        ),
        child: Center(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedHairline(animation: _topLine, color: gold),
                const SizedBox(height: 24),
                _WritingText(
                  text: 'بیاض',
                  progress: _writing,
                  style: const TextStyle(
                    fontSize: 96,
                    height: 1.1,
                    color: gold,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _subtitle,
                  child: Text(
                    'Bayaaz',
                    style: TextStyle(
                      fontSize: 14,
                      color: gold.withValues(alpha: 0.7),
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _AnimatedHairline(animation: _bottomLine, color: gold),
                const SizedBox(height: 28),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showColdStartHint ? 1.0 : 0.0,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(gold.withValues(alpha: 0.6)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Waking up server…',
                          style: TextStyle(
                            fontSize: 12,
                            color: gold.withValues(alpha: 0.65),
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedHairline extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  const _AnimatedHairline({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          width: 80 * animation.value,
          height: 1,
          color: color.withValues(alpha: 0.5),
        );
      },
    );
  }
}

// Reveals Urdu text right-to-left through a ShaderMask gradient, so the
// glyphs appear to be drawn by an invisible pen. A soft alpha edge at the
// writing frontier sells the "wet ink" feel without requiring SVG paths.
class _WritingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Animation<double> progress;
  const _WritingText({
    required this.text,
    required this.style,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final p = progress.value.clamp(0.0, 1.0);
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            stops: [
              0.0,
              (p - 0.04).clamp(0.0, 1.0),
              p.clamp(0.0, 1.0),
              1.0,
            ],
            colors: const [
              Colors.white,
              Colors.white,
              Colors.transparent,
              Colors.transparent,
            ],
          ).createShader(rect),
          child: Text(text, style: style, textDirection: TextDirection.rtl),
        );
      },
    );
  }
}
