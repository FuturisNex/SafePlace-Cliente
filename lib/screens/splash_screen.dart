import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/maintenance_service.dart';
import 'dart:async';
import '../widgets/app_logo.dart';
import '../utils/translations.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'language_selection_screen.dart';
import 'phone_required_screen.dart';
import '../config.dart';
import '../models/user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Aguardar tempo mínimo de splash + inicialização do AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Aguardar pelo menos 2 segundos para mostrar a splash
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      authProvider.waitForInitialization(),
    ]);
    
    if (!mounted) return;

    // Verificar manutenção
    final maintenanceStatus = await MaintenanceService.checkMaintenanceStatus();
    if (maintenanceStatus['enabled'] == true) {
      if (!mounted) return;
      _showMaintenanceDialog(maintenanceStatus['message'] as String);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSelectedLanguage = prefs.getBool('hasSelectedLanguage') ?? false;
    final hasSeenOnboarding =
        prefs.getBool(OnboardingScreen.hasSeenOnboardingKey) ?? false;
    final isBusinessVariant = kForcedUserType == UserType.business;

    // Removido: não faz mais logout automático se tipo não bate, pois a navegação já está protegida no HomeScreen

    if (!hasSelectedLanguage) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
      );
      return;
    }

    if (!hasSeenOnboarding && !isBusinessVariant) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    // Verificar se usuário tem telefone cadastrado
    if (authProvider.isAuthenticated) {
      final user = authProvider.user;
      final hasPhone = user?.phone != null && user!.phone!.trim().isNotEmpty;
      
      if (!hasPhone) {
        // Usuário autenticado mas sem telefone - redirecionar para tela de telefone
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PhoneRequiredScreen()),
        );
      } else {
        // Usuário autenticado com telefone - ir para home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _showMaintenanceDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.build, color: Colors.orange),
              SizedBox(width: 8),
              Text('Manutenção'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                // Tentar novamente
                Navigator.of(context).pop();
                _checkAuth();
              },
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            Text(
              Translations.getText(context, 'appName'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.getText(context, 'appSubtitle'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.getText(context, 'appSlogan'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}


