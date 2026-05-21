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
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_kalaam_screen.dart';
import 'screens/kalaam_detail_screen.dart';
import 'screens/practice_mode_screen.dart';
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
    // Watch the theme provider so the whole app rebuilds when the user flips
    // the sun/moon toggle. The colour palette below is shared across the
    // redesigned screens (home, detail, practice, my-bayaaz, create).
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp(
      title: 'Bayaaz',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF234547),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF234547),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        useMaterial3: true,
      ),
      home: const _SplashRouter(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/add': (_) => const AddKalaamScreen(),
        '/edit': (_) => const AddKalaamScreen(),
        '/kalaam': (_) => const KalaamDetailScreen(),
        '/practice': (_) => const PracticeModeScreen(),
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
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;

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
      duration: const Duration(milliseconds: 2200),
    );
    // Matches Figma keyframes 15:572 → 15:408: gradient holds, then title
    // fades in, then subtitle a touch later.
    _titleFade = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.30, 0.65, curve: Curves.easeOut),
    );
    _subtitleFade = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );
    _anim.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Keep the splash up for the full intro sequence even on instant boots.
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 2400));

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
    // Figma 15:572 / 15:408 — teal gradient splash with orange-gradient
    // wordmark and white Urdu welcome subtitle that fade in.
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF234547), Color(0xFF55A8AD)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // In Figma the title sits at ~40% of a 874px tall frame; the
              // subtitle sits ~9% below it. Reproduce that proportionally so
              // the layout holds on every device height.
              final titleTop = constraints.maxHeight * 0.40;
              return Stack(
                children: [
                  Positioned(
                    top: titleTop,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _titleFade,
                          child: const _GradientWordmark(),
                        ),
                        const SizedBox(height: 18),
                        FadeTransition(
                          opacity: _subtitleFade,
                          child: const Text(
                            'اسلام علیکم بیاز میں خوش آمدید',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.0,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.56,
                            ),
                          ),
                        ),
                      ],
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

// "بیاض" rendered with the orange Figma gradient (#FDA43F → #FDBA55) using a
// ShaderMask so the fill matches the source design exactly.
class _GradientWordmark extends StatelessWidget {
  const _GradientWordmark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFDA43F), Color(0xFFFDBA55)],
      ).createShader(rect),
      child: const Text(
        'بیاض',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 64,
          height: 1.0,
          color: Colors.white, // masked to the gradient above
          fontWeight: FontWeight.w500,
          letterSpacing: -1.28,
        ),
      ),
    );
  }
}
