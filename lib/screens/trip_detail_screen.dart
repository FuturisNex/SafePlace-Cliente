import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip.dart';
import '../models/establishment.dart';
import '../providers/establishment_provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import 'establishment_detail_screen.dart';

/// Tela de detalhes de um itinerário de viagem
class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> with SingleTickerProviderStateMixin {
  late Trip _trip;
  late TabController _tabController;
  int _selectedDayIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _tabController = TabController(length: _trip.days.length, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedDayIndex = _tabController.index);
    });
    
    // Se a viagem está em andamento, ir para o dia atual
    if (_trip.isOngoing && _trip.currentDay != null) {
      final currentDayIndex = _trip.days.indexWhere((d) => 
        d.date.year == DateTime.now().year &&
        d.date.month == DateTime.now().month &&
        d.date.day == DateTime.now().day
      );
      if (currentDayIndex >= 0) {
        _tabController.animateTo(currentDayIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildTripInfo()),
          SliverToBoxAdapter(child: _buildDayTabs()),
          SliverToBoxAdapter(child: _buildDayContent()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white),
          ),
          onPressed: _shareTrip,
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white),
          ),
          onPressed: _showOptions,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.shade400,
                Colors.teal.shade700,
              ],
            ),
          ),
          child: Stack(
            children: [
              if (_trip.coverImageUrl != null)
                Positioned.fill(
                  child: Image.network(
                    _trip.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _trip.status.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_trip.status.icon, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            _trip.status.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _trip.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_trip.destinations.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _trip.destinations.join(' → '),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripInfo() {
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoItem(
                icon: Icons.calendar_today,
                label: 'Período',
                value: '${_trip.startDate.day} ${months[_trip.startDate.month - 1]} - ${_trip.endDate.day} ${months[_trip.endDate.month - 1]}',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade200,
              ),
              _buildInfoItem(
                icon: Icons.schedule,
                label: 'Duração',
                value: '${_trip.durationDays} dias',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade200,
              ),
              _buildInfoItem(
                icon: Icons.place,
                label: 'Paradas',
                value: '${_trip.totalStops}',
              ),
            ],
          ),
          if (_trip.progress > 0) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progresso da viagem',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${(_trip.progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _trip.progress,
                  backgroundColor: Colors.grey.shade200,
                  color: AppTheme.primaryGreen,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs() {
    if (_trip.days.isEmpty) return const SizedBox();
    
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _trip.days.length,
        itemBuilder: (context, index) {
          final day = _trip.days[index];
          final isSelected = index == _selectedDayIndex;
          final isToday = day.date.year == DateTime.now().year &&
              day.date.month == DateTime.now().month &&
              day.date.day == DateTime.now().day;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDayIndex = index);
              _tabController.animateTo(index);
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: AppTheme.primaryGreen, width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Dia',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '${day.date.day}/${day.date.month}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayContent() {
    if (_trip.days.isEmpty) {
      return _buildEmptyDays();
    }
    
    final day = _trip.days[_selectedDayIndex];
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title ?? 'Dia ${_selectedDayIndex + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (day.description != null)
                      Text(
                        day.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (day.stops.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.place, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${day.stops.length} paradas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stops list
          if (day.stops.isEmpty)
            _buildEmptyStops()
          else
            ...day.stops.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;
              final isLast = index == day.stops.length - 1;
              return _buildStopCard(stop, isLast: isLast);
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyDays() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Nenhum dia planejado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione dias ao seu itinerário',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStops() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_location_alt, size: 32, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma parada neste dia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione restaurantes, cafés e atrações',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _addStop(_selectedDayIndex),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Adicionar Parada'),
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
      ),
    );
  }

  Widget _buildStopCard(TripStop stop, {bool isLast = false}) {
    return Column(
      children: [
        Container(
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
          child: InkWell(
            onTap: () => _openStopDetail(stop),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Time and type indicator
                  Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: stop.type.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          stop.type.icon,
                          color: stop.type.color,
                          size: 24,
                        ),
                      ),
                      if (stop.scheduledTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${stop.scheduledTime!.hour.toString().padLeft(2, '0')}:${stop.scheduledTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stop.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (stop.isCompleted)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stop.type.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: stop.type.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (stop.address != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  stop.address!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (stop.dietaryOptions != null && stop.dietaryOptions!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: stop.dietaryOptions!.take(3).map((diet) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  diet.label,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Actions
                  Column(
                    children: [
                      if (stop.latitude != null && stop.longitude != null)
                        IconButton(
                          icon: Icon(Icons.directions, color: Colors.blue.shade600),
                          onPressed: () => _openDirections(stop),
                          tooltip: 'Abrir rota',
                        ),
                      IconButton(
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                        onPressed: () => _showStopOptions(stop),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Connection line
        if (!isLast)
          Container(
            margin: const EdgeInsets.only(left: 40),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 24,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 12),
                if (stop.estimatedDurationMinutes != null)
                  Text(
                    '~${stop.estimatedDurationMinutes} min',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _addStop(_selectedDayIndex),
      backgroundColor: AppTheme.primaryGreen,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Adicionar Parada',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _addStop(int dayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddStopSheet(
        tripId: _trip.id,
        dayIndex: dayIndex,
        destinations: _trip.destinations,
        onStopAdded: (stop) {
          setState(() {
            final updatedDays = List<TripDay>.from(_trip.days);
            final day = updatedDays[dayIndex];
            final updatedStops = List<TripStop>.from(day.stops)..add(stop);
            updatedDays[dayIndex] = day.copyWith(stops: updatedStops);
            _trip = _trip.copyWith(days: updatedDays);
          });
          _saveTrip();
        },
      ),
    );
  }

  void _openStopDetail(TripStop stop) {
    if (stop.establishmentId != null) {
      final provider = Provider.of<EstablishmentProvider>(context, listen: false);
      final existingEst = provider.establishments.where((e) => e.id == stop.establishmentId).toList();
      
      if (existingEst.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => EstablishmentDetailScreen(establishment: existingEst.first),
        );
      } else {
        // Mostrar detalhes básicos se o estabelecimento não estiver carregado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${stop.name} - ${stop.address ?? "Sem endereço"}')),
        );
      }
    }
  }

  void _openStopDetailPlaceholder(TripStop stop) {
    // Placeholder para quando não há estabelecimento vinculado
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(),
    );
  }

  void _openDirections(TripStop stop) async {
    if (stop.latitude == null || stop.longitude == null) return;
    final lat = stop.latitude;
    final lng = stop.longitude;
    String url;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // Apple Maps
      url = 'http://maps.apple.com/?daddr=$lat,$lng';
    } else {
      // Google Maps
      url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o app de mapas.')),
      );
    }
  }

  void _showStopOptions(TripStop stop) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(stop.isCompleted ? 'Marcar como pendente' : 'Marcar como visitado'),
              onTap: () {
                Navigator.pop(context);
                _toggleStopCompleted(stop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar parada'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar edição
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remover parada', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _removeStop(stop);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleStopCompleted(TripStop stop) {
    setState(() {
      final updatedDays = _trip.days.map((day) {
        final updatedStops = day.stops.map((s) {
          if (s.id == stop.id) {
            return s.copyWith(isCompleted: !s.isCompleted);
          }
          return s;
        }).toList();
        return day.copyWith(stops: updatedStops);
      }).toList();
      _trip = _trip.copyWith(days: updatedDays);
    });
    _saveTrip();
  }

  void _removeStop(TripStop stop) {
    setState(() {
      final updatedDays = _trip.days.map((day) {
        final updatedStops = day.stops.where((s) => s.id != stop.id).toList();
        return day.copyWith(stops: updatedStops);
      }).toList();
      _trip = _trip.copyWith(days: updatedDays);
    });
    _saveTrip();
  }

  Future<void> _saveTrip() async {
    try {
      await FirebaseService.saveTrip(_trip.copyWith(updatedAt: DateTime.now()));
    } catch (e) {
      debugPrint('Erro ao salvar viagem: $e');
    }
  }

  void _shareTrip() {
    // TODO: Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartilhamento em breve!')),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar viagem'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar edição
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Ver rota completa'),
              onTap: () {
                Navigator.pop(context);
                _openFullRoute();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Excluir viagem', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteTrip();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openFullRoute() async {
    final allStops = _trip.days.expand((d) => d.stops).where((s) => s.latitude != null && s.longitude != null).toList();
    if (allStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma parada com localização')),
      );
      return;
    }
    
    final waypoints = allStops.map((s) => '${s.latitude},${s.longitude}').join('|');
    final url = 'https://www.google.com/maps/dir/?api=1&waypoints=$waypoints';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _deleteTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir viagem?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await FirebaseService.deleteTrip(_trip.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

/// Sheet para adicionar uma parada
class _AddStopSheet extends StatefulWidget {
  final String tripId;
  final int dayIndex;
  final List<String> destinations;
  final Function(TripStop) onStopAdded;
  
  const _AddStopSheet({
    required this.tripId,
    required this.dayIndex,
    required this.destinations,
    required this.onStopAdded,
  });

  @override
  State<_AddStopSheet> createState() => _AddStopSheetState();
}

class _AddStopSheetState extends State<_AddStopSheet> {
  String _searchQuery = '';
  StopType? _filterType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Adicionar Parada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar estabelecimentos...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          
          // Type filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeChip(null, 'Todos'),
                  ...StopType.values.take(5).map((type) => _buildTypeChip(type, type.label)),
                ],
              ),
            ),
          ),
          
          // Establishments list
          Expanded(
            child: Consumer<EstablishmentProvider>(
              builder: (context, provider, _) {
                var establishments = provider.establishments;
                
                // Filter by destination cities
                if (widget.destinations.isNotEmpty) {
                  establishments = establishments.where((e) {
                    return widget.destinations.any((dest) => 
                      (e.city ?? '').toLowerCase().contains(dest.toLowerCase()) ||
                      dest.toLowerCase().contains((e.city ?? '').toLowerCase())
                    );
                  }).toList();
                }
                
                // Filter by search
                if (_searchQuery.isNotEmpty) {
                  establishments = establishments.where((e) =>
                    e.name.toLowerCase().contains(_searchQuery) ||
                    e.category.toLowerCase().contains(_searchQuery)
                  ).toList();
                }
                
                if (establishments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum estabelecimento encontrado',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: establishments.length,
                  itemBuilder: (context, index) {
                    final est = establishments[index];
                    return _buildEstablishmentTile(est);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(StopType? type, String label) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterType = selected ? type : null);
        },
        selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildEstablishmentTile(Establishment est) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundImage: est.avatarUrl.isNotEmpty ? NetworkImage(est.avatarUrl) : null,
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
          child: est.avatarUrl.isEmpty ? const Icon(Icons.store, color: AppTheme.primaryGreen) : null,
        ),
        title: Text(
          est.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(est.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            if (est.dietaryOptions.isNotEmpty)
              Wrap(
                spacing: 4,
                children: est.dietaryOptions.take(2).map((d) => Text(
                  d.label,
                  style: TextStyle(fontSize: 10, color: AppTheme.primaryGreen),
                )).toList(),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _addEstablishment(est),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Adicionar', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  void _addEstablishment(Establishment est) {
    final stop = TripStop.fromEstablishment(
      est,
      order: 0, // Will be updated
    );
    widget.onStopAdded(stop);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${est.name} adicionado ao itinerário!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}
