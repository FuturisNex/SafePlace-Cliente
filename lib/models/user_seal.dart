import 'package:flutter/material.dart';

enum UserSeal {
  bronze, // Iniciante: cadastro + 1 check-in
  silver, // Colaborador: 10 avaliações, 5 check-ins, 2 indicações
  gold,   // Embaixador: mais de 25 avaliações, 10 indicações, participação em campanhas
}

extension UserSealExtension on UserSeal {
  String get label {
    switch (this) {
      case UserSeal.bronze:
        return 'Bronze';
      case UserSeal.silver:
        return 'Prata';
      case UserSeal.gold:
        return 'Ouro';
    }
  }

  String get description {
    switch (this) {
      case UserSeal.bronze:
        return 'Iniciante';
      case UserSeal.silver:
        return 'Colaborador';
      case UserSeal.gold:
        return 'Embaixador Prato Seguro';
    }
  }

  Color get color {
    switch (this) {
      case UserSeal.bronze:
        return const Color(0xFFCD7F32); // Bronze
      case UserSeal.silver:
        return const Color(0xFFC0C0C0); // Prata
      case UserSeal.gold:
        return const Color(0xFFFFD700); // Ouro
    }
  }
}

