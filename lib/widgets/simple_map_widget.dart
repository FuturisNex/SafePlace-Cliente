import 'package:flutter/material.dart';
import '../models/establishment.dart';

// Widget simplificado do mapa (sem Google Maps por enquanto)
// Em produção, substituir por GoogleMap widget
class SimpleMapWidget extends StatelessWidget {
  final List<Establishment> establishments;

  const SimpleMapWidget({
    super.key,
    required this.establishments,
  });

  @override
  Widget build(BuildContext context) {
    if (establishments.isEmpty) {
      return const Center(
        child: Text('Nenhum estabelecimento encontrado'),
      );
    }

    // Calcular centro do mapa
    double avgLat = establishments
        .map((e) => e.latitude)
        .reduce((a, b) => a + b) /
        establishments.length;
    double avgLng = establishments
        .map((e) => e.longitude)
        .reduce((a, b) => a + b) /
        establishments.length;

    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Mapa Interativo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${establishments.length} estabelecimentos encontrados',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Para usar o mapa completo com Google Maps, adicione a API key no pubspec.yaml e configure google_maps_flutter.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: establishments.map((e) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: e.difficultyLevel.color,
                    child: const Icon(Icons.location_on, size: 16, color: Colors.white),
                  ),
                  label: Text(e.name),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}


