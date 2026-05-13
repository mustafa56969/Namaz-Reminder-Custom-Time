import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'providers/reminder_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService().initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Pre-load SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  
runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ReminderProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        Provider.value(value: prefs),
        ChangeNotifierProvider(
            create: (context) => PrayerProvider(prefs: prefs, notificationService: NotificationService())),
        ChangeNotifierProvider(create: (context) => NotesProvider(prefs: prefs)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final isDark = themeProvider.mode == ThemeMode.dark || 
            (themeProvider.mode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
          
          final colorScheme = ColorScheme.fromSeed(
            seedColor: themeProvider.seedColor,
            brightness: isDark ? Brightness.dark : Brightness.light,
          );

          return MaterialApp(
            title: 'Prayer Reminder',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: colorScheme,
              textTheme: GoogleFonts.outfitTextTheme(
                ThemeData(brightness: colorScheme.brightness).textTheme,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              navigationBarTheme: NavigationBarThemeData(
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                height: 80,
                elevation: 0,
                backgroundColor: Colors.transparent,
                indicatorColor: colorScheme.primaryContainer,
              ),
            ),
            themeMode: themeProvider.mode,
            home: const InitScreen(),
          );
        },
      ),
    );
  }
}

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    // Load reminder provider after the widget is built
    await context.read<ReminderProvider>().loadReminders();
    
    final prefs = await SharedPreferences.getInstance();
    final hasAsked = prefs.getBool('notificationPermissionAsked') ?? false;
    
    if (!hasAsked && !kIsWeb) {
      // First time opening: go to PermissionScreen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PermissionScreen()),
        );
      }
    } else {
      // Not first time: check current status
      final hasPermission = await NotificationService().checkPermissionStatus();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_active,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
