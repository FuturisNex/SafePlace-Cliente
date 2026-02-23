import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/establishment_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/review_provider.dart';
import 'providers/feature_flags_provider.dart';
import 'services/notification_service.dart';
import 'services/mapbox_service.dart';
import 'services/app_cache_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase inicializado com sucesso!');
  } catch (e) {
    debugPrint('⚠️ Erro ao inicializar Firebase: $e');
    debugPrint('Verifique se google-services.json está em android/app/');
    // Continuar sem Firebase se não configurado
  }

  await AppCacheService.clearOnFirstLaunch();
  
  await NotificationService.initializeLocalNotifications();

  await MapboxService.initialize();
  
  runApp(const SafePlateApp());
}

class SafePlateApp extends StatelessWidget {
  const SafePlateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EstablishmentProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => FeatureFlagsProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
        title: 'Prato Seguro',
        debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}

