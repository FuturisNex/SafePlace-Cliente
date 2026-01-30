import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/establishment.dart';
import '../providers/establishment_provider.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';
import 'establishment_detail_screen.dart';
import '../services/firebase_service.dart';

class EstablishmentListScreen extends StatefulWidget {
  const EstablishmentListScreen({super.key});

  @override
  State<EstablishmentListScreen> createState() => _EstablishmentListScreenState();
}

class _EstablishmentListScreenState extends State<EstablishmentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          Translations.getText(context, 'establishmentsListTitle') == 'establishmentsListTitle'
              ? 'Locais' // Fallback se não tiver tradução
              : Translations.getText(context, 'establishmentsListTitle'),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryGreen),
      ),
      body: Column(
        children: [
          // Barra de busca local
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Filtrar por nome, cidade ou bairro...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Lista Hierárquica
          Expanded(
            child: Consumer<EstablishmentProvider>(
              builder: (context, provider, child) {
                final establishments = provider.establishments;
                
                if (establishments.isEmpty) {
                  return const Center(child: Text('Nenhum estabelecimento encontrado'));
                }

                // Agrupar estabelecimentos
                final groupedData = _groupEstablishments(establishments);
                
                if (groupedData.isEmpty) {
                  return const Center(child: Text('Nenhum local corresponde à busca'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // Espaço para bottom nav
                  itemCount: groupedData.length,
                  itemBuilder: (context, index) {
                    final state = groupedData.keys.elementAt(index);
                    final cities = groupedData[state]!;
                    
                    return _buildStateTile(state, cities);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Agrupa: Estado -> Cidade -> Bairro -> Lista de Estabelecimentos
  Map<String, Map<String, Map<String, List<Establishment>>>> _groupEstablishments(List<Establishment> list) {
    final Map<String, Map<String, Map<String, List<Establishment>>>> hierarchy = {};

    for (final est in list) {
      // Filtrar pela busca se houver
      if (_searchQuery.isNotEmpty) {
        final matchesName = est.name.toLowerCase().contains(_searchQuery);
        final matchesCity = (est.city ?? '').toLowerCase().contains(_searchQuery);
        final matchesNeighborhood = (est.neighborhood ?? '').toLowerCase().contains(_searchQuery);
        
        if (!matchesName && !matchesCity && !matchesNeighborhood) continue;
      }

      // Tentar obter dados de localização (fallback para endereço ou padrão)
      String state = est.state ?? _extractState(est.address) ?? 'Outros Estados';
      String city = est.city ?? _extractCity(est.address) ?? 'Outras Cidades';
      String neighborhood = est.neighborhood ?? _extractNeighborhood(est.address) ?? 'Outros Bairros';

      // Normalizar para evitar duplicatas por case/espaços
      state = state.trim();
      city = city.trim();
      neighborhood = neighborhood.trim();

      hierarchy.putIfAbsent(state, () => {});
      hierarchy[state]!.putIfAbsent(city, () => {});
      hierarchy[state]![city]!.putIfAbsent(neighborhood, () => []);
      hierarchy[state]![city]![neighborhood]!.add(est);
    }
    
    // Remover grupos vazios (se houver)
    return hierarchy;
  }

  // Helpers simples para extração (melhorar com regex real se necessário)
  String? _extractState(String? address) {
    if (address == null) return null;
    // Lógica simples: procurar UF no final (ex: "SP", "PR")
    // Isso é apenas um fallback básico
    if (address.contains('SP') || address.contains('São Paulo')) return 'São Paulo';
    if (address.contains('PR') || address.contains('Paraná')) return 'Paraná';
    if (address.contains('RJ') || address.contains('Rio de Janeiro')) return 'Rio de Janeiro';
    return null;
  }

  String? _extractCity(String? address) {
    if (address == null) return null;
    if (address.contains('Curitiba')) return 'Curitiba';
    if (address.contains('São Paulo')) return 'São Paulo';
    if (address.contains('Rio de Janeiro')) return 'Rio de Janeiro';
    return null;
  }

  String? _extractNeighborhood(String? address) {
    if (address == null) return null;
    // Tentar extrair bairro comum (ex: "Batel", "Vila Mariana")
    if (address.contains('Batel')) return 'Batel';
    if (address.contains('Centro')) return 'Centro';
    if (address.contains('Vila Mariana')) return 'Vila Mariana';
    if (address.contains('Pinheiros')) return 'Pinheiros';
    return null;
  }

  Widget _buildStateTile(String state, Map<String, Map<String, List<Establishment>>> cities) {
    return ExpansionTile(
      initiallyExpanded: true, // Começar expandido para facilitar
      leading: const Icon(Icons.map, color: AppTheme.primaryGreen),
      title: Text(
        state,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      children: cities.entries.map((entry) {
        return _buildCityTile(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildCityTile(String city, Map<String, List<Establishment>> neighborhoods) {
    return ExpansionTile(
      initiallyExpanded: true,
      leading: const Icon(Icons.location_city, color: Colors.grey),
      title: Text(
        city,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: neighborhoods.entries.map((entry) {
        return _buildNeighborhoodTile(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildNeighborhoodTile(String neighborhood, List<Establishment> establishments) {
    return ExpansionTile(
      initiallyExpanded: true,
      leading: const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
      title: Text(
        neighborhood,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: establishments.map((est) => _buildEstablishmentTile(est)).toList(),
    );
  }

  Widget _buildEstablishmentTile(Establishment establishment) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundImage: establishment.avatarUrl.isNotEmpty 
            ? NetworkImage(establishment.avatarUrl) 
            : null,
        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
        child: establishment.avatarUrl.isEmpty 
            ? const Icon(Icons.store, color: AppTheme.primaryGreen) 
            : null,
      ),
      title: Text(
        establishment.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        establishment.category,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        FirebaseService.registerEstablishmentClick(
          establishment.id,
          isSponsored: false,
        );
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => EstablishmentDetailScreen(
            establishment: establishment,
          ),
        );
      },
    );
  }
}
