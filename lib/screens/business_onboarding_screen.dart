import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';

class BusinessOnboardingScreen extends StatefulWidget {
  const BusinessOnboardingScreen({super.key});

  static const String hasSeenBusinessOnboardingKey = 'hasSeenBusinessOnboarding';

  @override
  State<BusinessOnboardingScreen> createState() => _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState extends State<BusinessOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_BusinessOnboardingPageData> get _pages => [
        _BusinessOnboardingPageData(
          icon: Icons.dashboard_customize,
          titleKey: 'businessOnboardingTitle1',
          descriptionKey: 'businessOnboardingDescription1',
        ),
        _BusinessOnboardingPageData(
          icon: Icons.insights_outlined,
          titleKey: 'businessOnboardingTitle2',
          descriptionKey: 'businessOnboardingDescription2',
        ),
        _BusinessOnboardingPageData(
          icon: Icons.campaign_outlined,
          titleKey: 'businessOnboardingTitle3',
          descriptionKey: 'businessOnboardingDescription3',
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(BusinessOnboardingScreen.hasSeenBusinessOnboardingKey, true);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  Translations.getText(context, 'onboardingSkip'),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.business_center,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          Translations.getText(context, page.titleKey),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Translations.getText(context, page.descriptionKey),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 10 : 6,
                        height: isActive ? 10 : 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? Translations.getText(context, 'onboardingStart')
                          : Translations.getText(context, 'onboardingNext'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessOnboardingPageData {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;

  _BusinessOnboardingPageData({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });
}
