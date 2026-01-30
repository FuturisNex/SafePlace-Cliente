import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/establishment_provider.dart';
import '../providers/auth_provider.dart';
import '../services/favorites_service.dart';
import '../widgets/establishment_card.dart';
import '../widgets/mapbox_map_widget.dart';
import '../models/establishment.dart';
import '../utils/translations.dart';
import '../theme/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  List<Establishment> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarregar favoritos quando o usuário mudar (login/logout)
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id ?? '';
    if (userId.isEmpty) {
      setState(() {
        _favorites = [];
        _isLoading = false;
      });
      return;
    }
    final favorites = await _favoritesService.getAllFavorites(userId);
    if (mounted) {
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Translations.getText(context, 'favoritesTitle'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_favorites.isNotEmpty)
                  Text(
                    '${_favorites.length} ${_favorites.length == 1 ? Translations.getText(context, 'favorite') : Translations.getText(context, 'favoritesPlural')}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          // Mapa e Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _favorites.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          // Mapa - ocupa mais espaço
                          Expanded(
                            flex: 3,
                            child: _buildMap(_favorites),
                          ),
                          // Lista de estabelecimentos
                          Expanded(
                            flex: 2,
                            child: _buildFavoritesList(_favorites),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            Translations.getText(context, 'noFavoritesYet'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Translations.getText(context, 'addRestaurantsToFavorites'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<Establishment> favorites) {
    return MapboxMapWidget(
      establishments: favorites,
      onMarkerTap: (establishment) async {
        // Mostrar diálogo para gerar rota
        final shouldRoute = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(establishment.name),
            content: Text('${Translations.getText(context, 'doYouWantToGo')} ${establishment.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(Translations.getText(context, 'cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(Translations.getText(context, 'generateRoute')),
              ),
            ],
          ),
        );

        if (shouldRoute == true) {
          _generateRoute(establishment);
        }
      },
    );
  }

  Widget _buildFavoritesList(List<Establishment> favorites) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        return EstablishmentCard(
          establishment: favorites[index],
          onSave: () async {
            await _loadFavorites();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${favorites[index].name} ${Translations.getText(context, 'removedFromFavorites')}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _generateRoute(Establishment establishment) async {
    try {
      final lat = establishment.latitude;
      final lng = establishment.longitude;
      final name = Uri.encodeComponent(establishment.name);
      
      // Tentar abrir diretamente com google.navigation primeiro
      try {
        final uri = Uri.parse('google.navigation:q=$lat,$lng');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Se falhar, tentar com maps URL
        try {
          final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          // Última tentativa: geo URI
          try {
            final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${Translations.getText(context, 'errorOpeningNavigation')} $e'),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Translations.getText(context, 'errorGeneratingRoute')} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

