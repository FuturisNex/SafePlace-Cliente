import 'package:flutter/material.dart';
import 'dart:async';
import '../models/establishment.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/mapbox_service.dart';

class EstablishmentProvider with ChangeNotifier {
  List<Establishment> _establishments = [];
  List<Establishment> _filteredEstablishments = [];
  Set<DietaryFilter> _selectedFilters = {};
  String _searchQuery = '';
  Position? _userPosition;
  bool _isLoading = false;
  StreamSubscription<List<Establishment>>? _establishmentsSubscription;
  
  // Filtros avançados
  double? _minRating;
  Set<String> _selectedCategories = {};
  Set<DifficultyLevel> _selectedDifficultyLevels = {};
  double _maxDistance = 50.0;

  List<Establishment> get establishments => _establishments;
  List<Establishment> get filteredEstablishments => _filteredEstablishments;
  Set<DietaryFilter> get selectedFilters => _selectedFilters;
  String get searchQuery => _searchQuery;
  Position? get userPosition => _userPosition;
  bool get isLoading => _isLoading;
  double? get minRating => _minRating;
  Set<String> get selectedCategories => _selectedCategories;
  Set<DifficultyLevel> get selectedDifficultyLevels => _selectedDifficultyLevels;
  double get maxDistance => _maxDistance;

  EstablishmentProvider() {
    _loadEstablishments();
    _listenToEstablishments();
  }

  void _listenToEstablishments() {
    // Escutar mudanças em tempo real do Firestore
    _establishmentsSubscription = FirebaseService.establishmentsStream().listen(
      (firestoreEstablishments) {
        debugPrint('🔄 Atualização em tempo real: ${firestoreEstablishments.length} estabelecimentos do Firestore');
        
        // Substituir lista completa com dados do Firestore
        _establishments = firestoreEstablishments;
        _filteredEstablishments = List.from(_establishments);
        
        debugPrint('📋 Total de estabelecimentos: ${_establishments.length}');
        _applyFilters();
        notifyListeners();
        _requestLocation();
      },
      onError: (error) {
        debugPrint('❌ Erro ao escutar estabelecimentos: $error');
      },
    );
  }

  @override
  void dispose() {
    _establishmentsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadEstablishments() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Carregar apenas do Firestore (sem dados mockados)
      final firestoreEstablishments = await FirebaseService.getAllEstablishments();
      debugPrint('📦 Carregados ${firestoreEstablishments.length} estabelecimentos do Firestore');
      
      if (firestoreEstablishments.isNotEmpty) {
        _establishments = firestoreEstablishments;
        _filteredEstablishments = List.from(_establishments);
        debugPrint('✅ ${firestoreEstablishments.length} estabelecimentos carregados');
        
        // LOG DETALHADO: Localização de cada estabelecimento
        for (final est in firestoreEstablishments) {
          debugPrint('   📍 ${est.name}: ${est.state ?? "?"} > ${est.city ?? "?"} > ${est.neighborhood ?? "?"}');
        }
      } else {
        debugPrint('⚠️ Nenhum estabelecimento encontrado no Firestore');
        _establishments = [];
        _filteredEstablishments = [];
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar estabelecimentos: $e');
      _establishments = [];
      _filteredEstablishments = [];
    } finally {
      _isLoading = false;
    }
    
    _applyFilters();
    notifyListeners();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    try {
      final hasPermission = await MapboxService.ensureLocationPermission();
      if (!hasPermission) {
        debugPrint('Permissão de localização não concedida');
        return;
      }

      _userPosition = await MapboxService.getCurrentPosition();
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
    }
    if (_userPosition == null) return;

    final updatedEstablishments = _establishments.map((establishment) {
      final distance = Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        establishment.latitude,
        establishment.longitude,
      );
      return Establishment(
        id: establishment.id,
        name: establishment.name,
        category: establishment.category,
        latitude: establishment.latitude,
        longitude: establishment.longitude,
        distance: distance / 1000, // Converter para km
        avatarUrl: establishment.avatarUrl,
        photoUrls: establishment.photoUrls,
        difficultyLevel: establishment.difficultyLevel,
        notes: establishment.notes,
        dietaryOptions: establishment.dietaryOptions,
        isOpen: establishment.isOpen,
        ownerId: establishment.ownerId,
        address: establishment.address,
        phone: establishment.phone,
        openingTime: establishment.openingTime,
        closingTime: establishment.closingTime,
        weekendOpeningTime: establishment.weekendOpeningTime,
        weekendClosingTime: establishment.weekendClosingTime,
        openingDays: establishment.openingDays,
        weeklySchedule: establishment.weeklySchedule,
        certificationStatus: establishment.certificationStatus,
        lastInspectionDate: establishment.lastInspectionDate,
        lastInspectionStatus: establishment.lastInspectionStatus,
        isBoosted: establishment.isBoosted,
        boostExpiresAt: establishment.boostExpiresAt,
        boostScore: establishment.boostScore,
        boostCampaignId: establishment.boostCampaignId,
        state: establishment.state,
        city: establishment.city,
        neighborhood: establishment.neighborhood,
        hasDelivery: establishment.hasDelivery,
        deliveryFee: establishment.deliveryFee,
        deliveryTimeMin: establishment.deliveryTimeMin,
        deliveryTimeMax: establishment.deliveryTimeMax,
        minOrderValue: establishment.minOrderValue,
        deliveryRadius: establishment.deliveryRadius,
        rating: establishment.rating,
        ratingCount: establishment.ratingCount,
      );
    }).toList();

    _establishments = updatedEstablishments;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void toggleFilter(DietaryFilter filter) {
    if (_selectedFilters.contains(filter)) {
      _selectedFilters.remove(filter);
    } else {
      _selectedFilters.add(filter);
    }
    _applyFilters();
  }

  void clearFilters() {
    _selectedFilters.clear();
    _applyFilters();
  }

  /// Adiciona um estabelecimento à lista local (sem recarregar do Firestore)
  void addEstablishment(Establishment establishment) {
    // Verificar se já existe (por ID)
    final existingIndex = _establishments.indexWhere((e) => e.id == establishment.id);
    if (existingIndex >= 0) {
      // Atualizar existente
      _establishments[existingIndex] = establishment;
      debugPrint('🔄 Estabelecimento atualizado: ${establishment.name} (${establishment.id})');
    } else {
      // Adicionar novo
      _establishments.add(establishment);
      debugPrint('➕ Estabelecimento adicionado: ${establishment.name} (${establishment.id})');
    }
    _applyFilters();
    notifyListeners();
  }

  Future<void> reloadEstablishments() async {
    await _loadEstablishments();
  }

  void setSelectedFilters(Set<DietaryFilter> filters) {
    _selectedFilters = filters;
    _applyFilters();
  }

  void setAdvancedFilters({
    double? minRating,
    Set<String>? categories,
    Set<DifficultyLevel>? difficultyLevels,
    double? maxDistance,
  }) {
    if (minRating != null) _minRating = minRating;
    if (categories != null) _selectedCategories = categories;
    if (difficultyLevels != null) _selectedDifficultyLevels = difficultyLevels;
    if (maxDistance != null) _maxDistance = maxDistance;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredEstablishments = _establishments.where((establishment) {
      // Filtro de busca
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = establishment.name.toLowerCase().contains(query);
        final matchesCategory =
            establishment.category.toLowerCase().contains(query);
        if (!matchesName && !matchesCategory) {
          return false;
        }
      }

      // Filtro de opções dietéticas
      // O estabelecimento deve ter TODOS os filtros selecionados (AND)
      if (_selectedFilters.isNotEmpty) {
        // Verificar se o estabelecimento tem TODOS os filtros selecionados
        final hasAllFilters = _selectedFilters.every(
          (filter) => establishment.dietaryOptions.contains(filter),
        );
        if (!hasAllFilters) {
          debugPrint('❌ ${establishment.name} não tem todos os filtros: ${_selectedFilters.map((f) => f.toString()).join(", ")}. Tem apenas: ${establishment.dietaryOptions.map((f) => f.toString()).join(", ")}');
          return false;
        }
        debugPrint('✅ ${establishment.name} tem todos os filtros: ${_selectedFilters.map((f) => f.toString()).join(", ")}');
      }

      // Filtros avançados
      // Filtro por categoria (case-insensitive)
      if (_selectedCategories.isNotEmpty) {
        // Normalizar categoria do estabelecimento e categorias selecionadas para comparação
        final establishmentCategory = establishment.category.toLowerCase().trim();
        final selectedCategories = _selectedCategories.map((c) => c.toLowerCase().trim()).toSet();
        
        if (!selectedCategories.contains(establishmentCategory)) {
          debugPrint('❌ ${establishment.name} filtrado: categoria "${establishment.category}" não está em ${_selectedCategories.join(", ")}');
          return false;
        }
        debugPrint('✅ ${establishment.name} passa no filtro de categoria: "${establishment.category}"');
      }

      // Filtro por nível de dificuldade
      if (_selectedDifficultyLevels.isNotEmpty) {
        if (!_selectedDifficultyLevels.contains(establishment.difficultyLevel)) {
          return false;
        }
      }

      // **REMOVIDO**: Filtro automático por distância máxima
      // Agora apenas filtra por distância quando usuário ativa "Próximos"
      // O usuário deve poder ver todo o Brasil no mapa
      // if (establishment.distance > _maxDistance) {
      //   return false;
      // }

      // Filtro por avaliação mínima (será implementado quando tiver avaliações)
      // TODO: Implementar quando tiver sistema de avaliações

      return true;
    }).toList();

    // Ordenar por prioridade: impulsionados ativos primeiro (por boostScore), depois certificados, depois premium, depois por distância
    final now = DateTime.now();
    _filteredEstablishments.sort((a, b) {
      // 1. Primeiro: estabelecimentos com boost ativo (ordenados por boostScore)
      final aBoostActive = a.isBoosted && (a.boostExpiresAt == null || a.boostExpiresAt!.isAfter(now));
      final bBoostActive = b.isBoosted && (b.boostExpiresAt == null || b.boostExpiresAt!.isAfter(now));
      
      if (aBoostActive && bBoostActive) {
        // Ambos têm boost ativo: ordenar por boostScore (maior primeiro)
        final aScore = a.boostScore ?? 0;
        final bScore = b.boostScore ?? 0;
        if (aScore != bScore) {
          return bScore.compareTo(aScore); // Maior score primeiro
        }
      } else if (aBoostActive != bBoostActive) {
        return aBoostActive ? -1 : 1;
      }

      // 2. Segundo: estabelecimentos certificados
      final aCertified = a.certificationStatus == TechnicalCertificationStatus.certified;
      final bCertified = b.certificationStatus == TechnicalCertificationStatus.certified;
      if (aCertified != bCertified) {
        return aCertified ? -1 : 1;
      }

      // 3. Terceiro: estabelecimentos premium (removido)

      // 4. Por último: ordenar por distância
      return a.distance.compareTo(b.distance);
    });

    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
