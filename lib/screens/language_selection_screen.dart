import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/translations.dart';
import 'onboarding_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _onLanguageSelected(BuildContext context, String code) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    localeProvider.selectLanguage(code);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSelectedLanguage', true);

    if (!context.mounted) return;

    // Após escolher idioma, ir para o onboarding na primeira vez.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppLogo(
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  Translations.getText(context, 'appName'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Translations.getText(context, 'appSubtitle'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  Translations.getText(context, 'language'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: size.width,
                  child: Column(
                    children: [
                      _LanguageButton(
                        code: 'PT',
                        label: 'Português',
                        isPrimary: true,
                        onTap: () => _onLanguageSelected(context, 'pt'),
                      ),
                      const SizedBox(height: 8),
                      _LanguageButton(
                        code: 'EN',
                        label: 'English',
                        isPrimary: false,
                        onTap: () => _onLanguageSelected(context, 'en'),
                      ),
                      const SizedBox(height: 8),
                      _LanguageButton(
                        code: 'ES',
                        label: 'Español',
                        isPrimary: false,
                        onTap: () => _onLanguageSelected(context, 'es'),
                      ),
                    ],
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

class _LanguageButton extends StatelessWidget {
  final String code;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.code,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isPrimary ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? Colors.green : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                code,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.green : Colors.grey.shade800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isPrimary ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
