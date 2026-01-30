import 'package:flutter/material.dart';
import '../models/seal.dart';

class SealScreen extends StatelessWidget {
  const SealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Selos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSealCard(
            Seal(
              id: '1',
              name: 'Selos de Confiabilidade',
              description:
                  'Sistema de certificação que garante a qualidade e segurança dos estabelecimentos.',
              level: SealLevel.gold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSealInfo(
            'Bronze',
            SealLevel.bronze,
            'Nível básico - Requisitos mínimos atendidos',
          ),
          const SizedBox(height: 16),
          _buildSealInfo(
            'Prata',
            SealLevel.silver,
            'Nível intermediário - Boas práticas implementadas',
          ),
          const SizedBox(height: 16),
          _buildSealInfo(
            'Ouro',
            SealLevel.gold,
            'Nível avançado - Excelência em segurança alimentar',
          ),
          const SizedBox(height: 16),
          _buildSealInfo(
            'Platina',
            SealLevel.platinum,
            'Nível máximo - Referência em qualidade e segurança',
          ),
        ],
      ),
    );
  }

  Widget _buildSealCard(Seal seal) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: seal.level.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seal.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: seal.level.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          seal.level.label,
                          style: TextStyle(
                            color: seal.level.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              seal.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSealInfo(String name, SealLevel level, String description) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: level.color,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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


