import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit? fit;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: FirebaseService.seasonalThemeStream(),
      builder: (context, snapshot) {
        final seasonalTheme = snapshot.data;
        String imagePath = 'assets/images/logo.png';

        if (seasonalTheme == 'christmas') {
          imagePath = 'sazonalLogo/logonatal.png';
        }

        return Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // Fallback para logo original se a sazonal falhar
            return Image.asset(
              'assets/images/logo.png',
              width: width,
              height: height,
              fit: fit,
            );
          },
        );
      },
    );
  }
}
