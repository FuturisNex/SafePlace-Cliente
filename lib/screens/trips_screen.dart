import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import 'trip_detail_screen.dart';
import 'create_trip_screen.dart';

/// Tela principal de Itinerários de Viagem
/// Substitui a antiga lista de cidades por um recurso completo de planejamento
/// Design SaaS moderno: sem header próprio (usa o do HomeScreen), cards limpos.
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Trip> _trips = [];
  bool _isLoading = true;
  String? _error;

  static const Color _bgColor = Color(0xFFF7F8FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      debugPrint('🔍 TripsScreen: Carregando viagens para userId: $userId');
      
      if (userId != null) {
        final trips = await FirebaseService.getUserTrips(userId);
        debugPrint('✅ TripsScreen: ${trips.length} viagens carregadas');
        if (mounted) {
          setState(() {
            _trips = trips;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('⚠️ TripsScreen: Usuário não logado');
        if (mounted) {
          setState(() {
            _trips = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ TripsScreen: Erro ao carregar viagens: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Trip> get _upcomingTrips => _trips.where((t) => 
      t.status == TripStatus.planning || 
      t.status == TripStatus.upcoming ||
      t.status == TripStatus.ongoing
  ).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));

  List<Trip> get _pastTrips => _trips.where((t) => 
      t.status == TripStatus.completed || 
      t.status == TripStatus.cancelled
  ).toList()..sort((a, b) => b.startDate.compareTo(a.startDate));

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const navApproxHeight = 96.0;

    return Container(
      color: _bgColor,
      child: Column(
        children: [
          // Card de título compacto
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildTitleCard(context),
          ),
          
          // Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildTabBar(),
          ),
          
          // Conteúdo das tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTripsTab(_upcomingTrips, isUpcoming: true, bottomPadding: bottomPadding + navApproxHeight + 20),
                _buildTripsTab(_pastTrips, isUpcoming: false, bottomPadding: bottomPadding + navApproxHeight + 20),
                _buildExploreTab(bottomPadding: bottomPadding + navApproxHeight + 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkGreen,
            AppTheme.primaryGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.luggage,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Minhas Viagens',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Planeje sua próxima aventura segura',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Botão de criar viagem
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _createNewTrip,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: AppTheme.primaryGreen, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Nova',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flight_takeoff, size: 16),
                const SizedBox(width: 4),
                Text('Próximas (${_upcomingTrips.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, size: 16),
                const SizedBox(width: 4),
                Text('Passadas (${_pastTrips.length})'),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore, size: 16),
                SizedBox(width: 4),
                Text('Explorar'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsTab(List<Trip> trips, {required bool isUpcoming, required double bottomPadding}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Erro ao carregar viagens', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadTrips,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (trips.isEmpty) {
      return _buildEmptyState(isUpcoming, bottomPadding);
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return _buildTripCard(trips[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isUpcoming, double bottomPadding) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(32, 32, 32, bottomPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUpcoming ? Icons.luggage : Icons.photo_album,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isUpcoming 
                ? 'Nenhuma viagem planejada' 
                : 'Nenhuma viagem realizada',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isUpcoming
                ? 'Comece a planejar sua próxima aventura gastronômica!'
                : 'Suas viagens concluídas aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewTrip,
              icon: const Icon(Icons.add),
              label: const Text('Criar Itinerário'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final isOngoing = trip.isOngoing;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isOngoing 
            ? Border.all(color: AppTheme.primaryGreen, width: 2)
            : null,
      ),
      child: InkWell(
        onTap: () => _openTripDetail(trip),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image ou placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.teal.shade300,
                          Colors.teal.shade600,
                        ],
                      ),
                    ),
                    child: trip.coverImageUrl != null
                        ? Image.network(
                            trip.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildCoverPlaceholder(trip),
                          )
                        : _buildCoverPlaceholder(trip),
                  ),
                  // Status badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: trip.status.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(trip.status.icon, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            trip.status.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Duration badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${trip.durationDays} ${trip.durationDays == 1 ? 'dia' : 'dias'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Destinations
                  if (trip.destinations.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trip.destinations.join(' → '),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Dates
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateRange(trip.startDate, trip.endDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Stats row
                  Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.place,
                        label: '${trip.totalStops} paradas',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        icon: Icons.restaurant,
                        label: '${trip.days.fold(0, (sum, d) => sum + d.stops.where((s) => s.type == StopType.meal || s.type == StopType.snack || s.type == StopType.coffee).length)} refeições',
                        color: Colors.orange,
                      ),
                      const Spacer(),
                      if (trip.progress > 0)
                        _buildProgressIndicator(trip.progress),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder(Trip trip) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flight, size: 40, color: Colors.white70),
          const SizedBox(height: 8),
          if (trip.destinations.isNotEmpty)
            Text(
              trip.destinations.first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return Container(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: AppTheme.primaryGreen,
            strokeWidth: 4,
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreTab({required double bottomPadding}) {
    return Consumer<EstablishmentProvider>(
      builder: (context, provider, _) {
        final establishments = provider.establishments;
        
        // Agrupar por cidade
        final Map<String, List<dynamic>> citiesMap = {};
        for (final est in establishments) {
          final city = est.city ?? 'Outras Cidades';
          citiesMap.putIfAbsent(city, () => []);
          citiesMap[city]!.add(est);
        }
        
        final cities = citiesMap.keys.toList()..sort();
        
        if (cities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Nenhum destino disponível',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
          itemCount: cities.length,
          itemBuilder: (context, index) {
            final city = cities[index];
            final count = citiesMap[city]!.length;
            
            return _buildCityCard(city, count);
          },
        );
      },
    );
  }

  Widget _buildCityCard(String city, int establishmentCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.location_city, color: Colors.teal.shade600),
        ),
        title: Text(
          city,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$establishmentCount ${establishmentCount == 1 ? 'local seguro' : 'locais seguros'}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: ElevatedButton(
          onPressed: () => _createTripForCity(city),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Text('Planejar', style: TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} - ${end.day} ${months[start.month - 1]} ${start.year}';
    } else if (start.year == end.year) {
      return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${start.year}';
    } else {
      return '${start.day} ${months[start.month - 1]} ${start.year} - ${end.day} ${months[end.month - 1]} ${end.year}';
    }
  }

  void _createNewTrip() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateTripScreen(),
      ),
    ).then((_) => _loadTrips());
  }

  void _createTripForCity(String city) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTripScreen(initialDestination: city),
      ),
    ).then((_) => _loadTrips());
  }

  void _openTripDetail(Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TripDetailScreen(trip: trip),
      ),
    ).then((_) => _loadTrips());
  }
}
