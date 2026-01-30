import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/establishment.dart';
import '../services/mapbox_service.dart';
import '../services/notification_service.dart';
import '../utils/translations.dart';
import '../widgets/welcome_dialog.dart';
import 'empty_map_state.dart';

class MapboxMapWidget extends StatefulWidget {
  final List<Establishment> establishments;
  final Function(Establishment)? onMarkerTap;
  final VoidCallback? onMapInteraction;
  final GlobalKey<MapboxMapWidgetState>? mapStateKey;
  final VoidCallback? onSuggestEstablishment;
  final VoidCallback? onMapInteractionEnd;

  const MapboxMapWidget({
    super.key,
    required this.establishments,
    this.onMarkerTap,
    this.onMapInteraction,
    this.mapStateKey,
    this.onSuggestEstablishment,
    this.onMapInteractionEnd,
  });

  @override
  State<MapboxMapWidget> createState() => MapboxMapWidgetState();
}

class MapboxMapWidgetState extends State<MapboxMapWidget> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  CircleAnnotationManager? circleAnnotationManager;
  bool _isMapReady = false;
  bool _isModalVisible = true;
  geo.Position? _userPosition;
  StreamSubscription<geo.Position>? _positionStream;
  CircleAnnotation? _userLocationCircle;
  // Mapa para relacionar IDs dos marcadores com estabelecimentos
  final Map<String, Establishment> _markerIdToEstablishment = {};
  // Lista de círculos de estabelecimentos para poder deletá-los depois
  final List<CircleAnnotation> _establishmentCircles = [];
  Establishment? _nearbyEstablishment;
  double? _nearbyDistanceKm;
  DateTime? _lastProximityNotificationAt;
  String? _lastProximityNotificationEstablishmentId;
  Set<DietaryFilter>? _preferredDietaryFilters;
  bool _hasAutoCenteredOnUser = false; // Garante auto-centro apenas uma vez
  bool _noResultsDialogShown =
      false; // Evita mostrar o dialog de "sem resultados" repetidamente
  Offset? _pointerDownPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    MapboxService.initialize();
    _initLocation();
    _loadPreferredDietaryFilters();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _markerIdToEstablishment.clear();
    super.dispose();
  }

  Future<void> _initLocation() async {
    // Primeiro, tentar obter a posição atual (isso já cuida de pedir permissão)
    await _getUserLocation();

    if (!mounted) return;

    // Só iniciar o stream contínuo se a permissão tiver sido realmente concedida
    final permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse) {
      _startLocationUpdates();
    } else {
      debugPrint(
          '⚠️ Permissão de localização não concedida, não iniciando stream contínuo');
    }
  }

  @override
  void didUpdateWidget(MapboxMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se os estabelecimentos mudaram (filtros ou busca), atualizar marcadores
    // Comparar IDs para detectar mudanças (mais eficiente que comparar objetos inteiros)
    final oldIds = oldWidget.establishments.map((e) => e.id).toSet();
    final newIds = widget.establishments.map((e) => e.id).toSet();
    final hasChanged = oldIds.length != newIds.length ||
        !oldIds.containsAll(newIds) ||
        !newIds.containsAll(oldIds);

    if (hasChanged) {
      debugPrint(
          '🔄 Estabelecimentos mudaram: ${oldWidget.establishments.length} -> ${widget.establishments.length}');
      if (widget.establishments.isNotEmpty) {
        _noResultsDialogShown = false;
      }
      if (mounted && _isMapReady) {
        _addMarkers();
      }
    }
  }

  Future<void> _getUserLocation() async {
    final position = await MapboxService.getCurrentPosition();
    if (mounted && position != null) {
      setState(() {
        _userPosition = position;
      });
    }
  }

  void _startLocationUpdates() {
    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter:
            5, // Atualizar a cada 5 metros para movimento mais suave
      ),
    ).listen((position) {
      if (mounted) {
        debugPrint(
            'Nova posição recebida: ${position.latitude}, ${position.longitude}');
        setState(() {
          _userPosition = position;
        });

        // Atualizar círculo do usuário se o mapa estiver pronto
        if (_isMapReady &&
            mapboxMap != null &&
            circleAnnotationManager != null) {
          _updateUserMarker();
        }
        _checkNearbyEstablishments();

        // Auto-centralizar apenas uma vez quando recebermos a primeira posição
        if (_isMapReady && !_hasAutoCenteredOnUser && mapboxMap != null) {
          _hasAutoCenteredOnUser = true;
          centerOnUser();
        }
      }
    }, onError: (error) {
      debugPrint('Erro ao obter posição: $error');
    });
  }

  Future<void> _loadPreferredDietaryFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson == null) return;

      final data = json.decode(userJson) as Map<String, dynamic>;
      final raw = data['dietaryPreferences'];
      if (raw is List) {
        final filters = raw
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .map(DietaryFilter.fromString)
            .toSet();
        if (filters.isNotEmpty) {
          if (mounted) {
            setState(() {
              _preferredDietaryFilters = filters;
            });
          } else {
            _preferredDietaryFilters = filters;
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar preferências dietéticas no mapa: $e');
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    try {
      debugPrint('🗺️ Inicializando Mapbox...');

      // Esconder ornamentos nativos do Mapbox (scale bar, compass, logo, attribution)
      try {
        await mapboxMap.scaleBar
            .updateSettings(ScaleBarSettings(enabled: false));
        debugPrint('✅ Scale bar desabilitada');
      } catch (e) {
        debugPrint('⚠️ Não foi possível desabilitar scale bar: $e');
      }
      try {
        await mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
        debugPrint('✅ Compass desabilitado');
      } catch (e) {
        debugPrint('⚠️ Não foi possível desabilitar compass: $e');
      }
      try {
        await mapboxMap.logo.updateSettings(LogoSettings(enabled: false));
        debugPrint('✅ Logo desabilitado');
      } catch (e) {
        debugPrint('⚠️ Não foi possível desabilitar logo: $e');
      }
      try {
        await mapboxMap.attribution
            .updateSettings(AttributionSettings(enabled: false));
        debugPrint('✅ Attribution desabilitada');
      } catch (e) {
        debugPrint('⚠️ Não foi possível desabilitar attribution: $e');
      }

      final pointManager =
          await mapboxMap.annotations.createPointAnnotationManager();
      pointAnnotationManager = pointManager;
      debugPrint('✅ PointAnnotationManager criado');

      final circleManager =
          await mapboxMap.annotations.createCircleAnnotationManager();
      circleAnnotationManager = circleManager;
      debugPrint('✅ CircleAnnotationManager criado');

      setState(() {
        _isMapReady = true;
      });

      // Configurar listeners de interação com mapa
      _setupMapInteractionListeners();

      // Aguardar um pouco para o mapa carregar completamente
      await Future.delayed(const Duration(milliseconds: 1500));

      // Adicionar marcadores
      debugPrint('📍 Iniciando adição de marcadores...');
      _addMarkers();

      // Adicionar/atualizar marcador do usuário se já tiver posição
      if (_userPosition != null) {
        debugPrint('👤 Adicionando círculo azul inicial do usuário');
        await _updateUserMarker();
        _checkNearbyEstablishments();

        // Centralizar no usuário na primeira vez que o mapa fica pronto
        if (!_hasAutoCenteredOnUser) {
          _hasAutoCenteredOnUser = true;
          centerOnUser();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao inicializar Mapbox: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _setupMapInteractionListeners() {
    // TODO: Implementar listeners de interação quando API correta for identificada
    // A versão 2.12.0 do mapbox_maps_flutter não possui addOnMapClickListener
    // Por enquanto, a seção em destaque ficará sempre visível
    // Para adicionar comportamento de ocultar/mostrar, seria necessário usar:
    // - Polling de câmera position
    // - Wrapper com GestureDetector
    // - Atualização para versão mais recente do Mapbox

    if (widget.onMapInteraction != null) {
      debugPrint(
          '⚠️ Callback de interação configurado mas listeners não implementados nesta versão do Mapbox');
    }
  }

  Future<void> _updateUserMarker() async {
    if (circleAnnotationManager == null || _userPosition == null) return;

    try {
      // Remover círculo antigo se existir
      if (_userLocationCircle != null) {
        try {
          await circleAnnotationManager!.delete(_userLocationCircle!);
        } catch (e) {
          debugPrint('Erro ao remover círculo antigo: $e');
        }
      }

      // Criar círculo azul central (similar ao Google Maps/Uber)
      final circleOptions = CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            _userPosition!.longitude,
            _userPosition!.latitude,
          ),
        ),
        circleRadius: 8.0, // Raio do círculo azul central
        circleColor: 0xFF2196F3, // Azul #2196F3
        circleStrokeColor: 0xFFFFFFFF, // Borda branca
        circleStrokeWidth: 3.0, // Largura da borda branca
      );

      _userLocationCircle =
          await circleAnnotationManager!.create(circleOptions);

      // Criar círculo de pulsação maior e semi-transparente ao redor
      final pulseOptions = CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            _userPosition!.longitude,
            _userPosition!.latitude,
          ),
        ),
        circleRadius: 18.0, // Círculo maior ao redor
        circleColor: 0x202196F3, // Azul muito transparente (pulsação)
        circleStrokeColor: 0x602196F3, // Borda azul semi-transparente
        circleStrokeWidth: 2.0,
      );

      await circleAnnotationManager!.create(pulseOptions);
      debugPrint(
          '✅ Localização do usuário atualizada: ${_userPosition!.latitude}, ${_userPosition!.longitude}');
    } catch (e) {
      debugPrint('❌ Erro ao criar/atualizar círculo do usuário: $e');
    }
  }

  void navigateToEstablishment(Establishment establishment) {
    if (mapboxMap == null) return;
    mapboxMap!.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            establishment.longitude,
            establishment.latitude,
          ),
        ),
        zoom: 16.0,
      ),
      MapAnimationOptions(duration: 1500, startDelay: 0),
    );
  }

  void centerOnUser() {
    if (mapboxMap == null) return;

    double targetLat = _userPosition?.latitude ?? -23.5505; // SP Default
    double targetLng = _userPosition?.longitude ?? -46.6333;
    double targetZoom = 10.5;

    if (_userPosition != null) {
      // Sempre centralizar no usuário quando a posição está disponível
      targetLat = _userPosition!.latitude;
      targetLng = _userPosition!.longitude;
    } else if (widget.establishments.isNotEmpty) {
      // Sem GPS, foca nos estabelecimentos
      double sumLat = 0;
      double sumLng = 0;
      for (final est in widget.establishments) {
        sumLat += est.latitude;
        sumLng += est.longitude;
      }
      targetLat = sumLat / widget.establishments.length;
      targetLng = sumLng / widget.establishments.length;
    }

    _hasAutoCenteredOnUser = true;

    mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(targetLng, targetLat)),
        zoom: targetZoom,
        padding: MbxEdgeInsets(top: 320.0, left: 0.0, bottom: 0.0, right: 0.0),
      ),
      MapAnimationOptions(duration: 1000, startDelay: 0),
    );
  }

  /// Handler para tap no mapa - tenta identificar qual marcador foi tocado
  Future<void> _handleMapTap(ScreenCoordinate point) async {
    if (mapboxMap == null) {
      debugPrint('⚠️ Mapbox não disponível');
      return;
    }

    try {
      debugPrint(
          '🔍 Convertendo coordenada da tela (${point.x}, ${point.y}) para geográfica...');
      // Converter coordenada da tela para coordenada geográfica
      final pointGeo = await mapboxMap!.coordinateForPixel(point);
      final coords = pointGeo.coordinates;

      double tapLat = 0.0;
      double tapLng = 0.0;

      // Position no mapbox_maps_flutter armazena [longitude, latitude]
      // Precisamos acessar os valores diretamente do objeto Position
      try {
        // Position pode ser acessado via índices ou propriedades
        // Tentar acessar como lista primeiro (Position pode implementar List)
        if (coords is List) {
          if (coords.length >= 2) {
            tapLng = (coords[0] as num).toDouble();
            tapLat = (coords[1] as num).toDouble();
            debugPrint(
                '📍 Coordenada do tap (via List): lat=$tapLat, lng=$tapLng');
          } else {
            debugPrint('⚠️ Lista não tem elementos suficientes');
            return;
          }
        } else {
          // Position não é List, tentar acessar via propriedades ou método toString
          // Position armazena [longitude, latitude] - tentar converter para lista
          final posStr = coords.toString();
          debugPrint('🔍 Position como string: $posStr');

          // Tentar acessar via índices usando dynamic
          final dynamic pos = coords;
          try {
            // Tentar acessar como se fosse uma lista
            tapLng = (pos[0] as num).toDouble();
            tapLat = (pos[1] as num).toDouble();
            debugPrint(
                '📍 Coordenada do tap (via índices): lat=$tapLat, lng=$tapLng');
          } catch (e2) {
            debugPrint('❌ Não foi possível acessar via índices: $e2');
            // Última tentativa: usar reflection ou toString parsing
            // Position geralmente tem formato [longitude, latitude]
            final match =
                RegExp(r'\[([-\d.]+),\s*([-\d.]+)\]').firstMatch(posStr);
            if (match != null) {
              tapLng = double.parse(match.group(1)!);
              tapLat = double.parse(match.group(2)!);
              debugPrint(
                  '📍 Coordenada do tap (via regex): lat=$tapLat, lng=$tapLng');
            } else {
              debugPrint('❌ Não foi possível extrair coordenadas de: $posStr');
              return;
            }
          }
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Erro ao extrair coordenadas: $e');
        debugPrint('   Tipo: ${coords.runtimeType}');
        debugPrint('   Stack: $stackTrace');
        return;
      }

      // Encontrar o estabelecimento mais próximo do ponto tocado
      // Usar distância em PIXELS na tela (muito mais preciso que graus)
      Establishment? nearestEstablishment;
      double minDistancePixels = double.infinity;
      // Raio de detecção em pixels - ajustado para o novo tamanho dos marcadores (raio 18px + borda)
      const maxDistancePixels =
          35.0; // Raio máximo em pixels - detecta cliques no marcador e área próxima

      debugPrint(
          '🔍 Procurando estabelecimento próximo entre ${widget.establishments.length} estabelecimentos (raio: ${maxDistancePixels}px)...');
      for (final establishment in widget.establishments) {
        try {
          // Converter coordenada do estabelecimento para pixel na tela
          final establishmentPoint = Point(
            coordinates: Position(
              establishment.longitude,
              establishment.latitude,
            ),
          );
          final establishmentPixel =
              await mapboxMap!.pixelForCoordinate(establishmentPoint);

          // Calcular distância em pixels entre o tap e o marcador
          final dx = point.x - establishmentPixel.x;
          final dy = point.y - establishmentPixel.y;
          final distancePixels = math.sqrt(dx * dx + dy * dy);

          debugPrint(
              '  📍 ${establishment.name}: distância=${distancePixels.toStringAsFixed(1)}px');

          if (distancePixels < maxDistancePixels &&
              distancePixels < minDistancePixels) {
            minDistancePixels = distancePixels;
            nearestEstablishment = establishment;
          }
        } catch (e) {
          debugPrint(
              '  ⚠️ Erro ao calcular distância para ${establishment.name}: $e');
        }
      }

      if (nearestEstablishment != null && widget.onMarkerTap != null) {
        // Verificar se a distância está realmente dentro do limite restrito
        if (minDistancePixels <= maxDistancePixels) {
          debugPrint(
              '✅ ✅ ✅ MARCADOR TOCADO: ${nearestEstablishment.name} (distância: ${minDistancePixels.toStringAsFixed(1)}px) ✅ ✅ ✅');
          // Adicionar feedback visual ao tocar (animar o círculo)
          _animateMarkerTap(nearestEstablishment);
          widget.onMarkerTap!(nearestEstablishment);
        } else {
          debugPrint(
              '⚠️ Estabelecimento encontrado mas fora do raio permitido: ${nearestEstablishment.name} (distância: ${minDistancePixels.toStringAsFixed(1)}px > ${maxDistancePixels}px)');
        }
      } else if (nearestEstablishment == null) {
        debugPrint(
            '⚠️ Nenhum estabelecimento encontrado próximo do ponto tocado (raio: ${maxDistancePixels}px)');
        // Não listar todos os estabelecimentos para não poluir os logs
      } else {
        debugPrint('⚠️ onMarkerTap callback não definido');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao processar tap no mapa: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Calcula distância entre dois pontos geográficos usando fórmula de Haversine (em graus)
  /// Retorna a distância euclidiana em graus para comparação rápida
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    final latDiff = lat1 - lat2;
    final lngDiff = lng1 - lng2;
    // Usar distância euclidiana simples (mais rápida que Haversine para comparações)
    // Como estamos comparando apenas para encontrar o mais próximo, não precisamos da distância real
    return (latDiff * latDiff + lngDiff * lngDiff).abs();
  }

  /// Anima o marcador quando tocado (feedback visual)
  Future<void> _animateMarkerTap(Establishment establishment) async {
    if (circleAnnotationManager == null) return;

    try {
      // Criar um círculo temporário maior e mais brilhante para feedback visual
      final feedbackCircle = await circleAnnotationManager!.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              establishment.longitude,
              establishment.latitude,
            ),
          ),
          circleRadius: 25.0, // Círculo maior para feedback
          circleColor: 0x804CAF50, // Verde mais transparente
          circleStrokeColor: 0xFF4CAF50, // Borda verde sólida
          circleStrokeWidth: 4.0,
        ),
      );

      // Remover após animação (após 300ms)
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        await circleAnnotationManager!.delete(feedbackCircle);
      } catch (e) {
        // Ignorar erro se já foi deletado
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao animar marcador: $e');
    }
  }

  /// Adiciona marcadores usando círculos coloridos (visíveis) + texto
  void _addMarkers() async {
    if (pointAnnotationManager == null) {
      debugPrint('❌ PointAnnotationManager é null');
      return;
    }

    if (circleAnnotationManager == null) {
      debugPrint('❌ CircleAnnotationManager é null');
      return;
    }

    if (widget.establishments.isEmpty) {
      debugPrint('⚠️ Nenhum estabelecimento para adicionar');
      // Mesmo sem estabelecimentos, deletar marcadores antigos
      try {
        await pointAnnotationManager!.deleteAll();
        debugPrint('🗑️ Todas as anotações de texto deletadas (lista vazia)');
      } catch (e) {
        debugPrint('⚠️ Erro ao deletar anotações: $e');
      }
      for (final circle in _establishmentCircles) {
        try {
          await circleAnnotationManager!.delete(circle);
        } catch (e) {
          // Ignorar erro se já foi deletado
        }
      }
      _establishmentCircles.clear();

      // Mostrar popup de "sem resultados" se ainda não foi mostrado
      if (!_noResultsDialogShown && mounted) {
        _noResultsDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          EmptyMapState.show(
            context,
            onExpandSearch: () {
              mapboxMap?.flyTo(
                CameraOptions(zoom: 8.0),
                MapAnimationOptions(duration: 1000),
              );
            },
          );
        });
      }
      return;
    }

    debugPrint('📍 Adicionando ${widget.establishments.length} marcadores...');

    // === DELETAR TODAS AS ANOTAÇÕES ANTIGAS (textos E círculos) ===
    try {
      await pointAnnotationManager!.deleteAll();
      debugPrint('🗑️ Todas as anotações de texto deletadas');
    } catch (e) {
      debugPrint('⚠️ Erro ao deletar anotações antigas: $e');
    }

    for (final circle in _establishmentCircles) {
      try {
        await circleAnnotationManager!.delete(circle);
      } catch (e) {
        // Ignorar se já foi deletado
      }
    }
    _establishmentCircles.clear();
    debugPrint('🗑️ Todos os círculos antigos deletados');

    // Limpar mapa de referências
    _markerIdToEstablishment.clear();

    final annotations = <PointAnnotationOptions>[];

    // Criar anotações de texto para os nomes
    for (final establishment in widget.establishments) {
      debugPrint(
          '  📌 Preparando marcador para ${establishment.name} em (${establishment.latitude}, ${establishment.longitude})');

      annotations.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              establishment.longitude,
              establishment.latitude,
            ),
          ),
          // Texto com nome do estabelecimento
          textField: establishment.name,
          textOffset: [0.0, -2.5],
          textAnchor: TextAnchor.BOTTOM,
          textColor: 0xFF4CAF50, // Verde
          textSize: 13.0,
          textHaloColor: 0xFFFFFFFF, // Halo branco para contraste
          textHaloWidth: 2.0,
        ),
      );
    }

    try {
      debugPrint('🚀 Criando ${annotations.length} anotações de texto...');
      final createdAnnotations =
          await pointAnnotationManager!.createMulti(annotations);
      debugPrint('✅ ${createdAnnotations.length} anotações de texto criadas!');

      // Criar círculos coloridos para cada estabelecimento (mais visíveis que apenas texto)
      debugPrint('🎨 Criando círculos coloridos para os marcadores...');
      int circlesCreated = 0;

      // Limpar círculos antigos de estabelecimentos
      for (final circle in _establishmentCircles) {
        try {
          await circleAnnotationManager!.delete(circle);
        } catch (e) {
          // Ignorar erro se o círculo já foi deletado
        }
      }
      _establishmentCircles.clear();

      for (final establishment in widget.establishments) {
        try {
          // Círculo externo com sombra/brilho para indicar que é clicável (efeito visual)
          final outerGlow = await circleAnnotationManager!.create(
            CircleAnnotationOptions(
              geometry: Point(
                coordinates: Position(
                  establishment.longitude,
                  establishment.latitude,
                ),
              ),
              circleRadius: 18.0, // Círculo externo maior
              circleColor: 0x204CAF50, // Verde muito transparente (brilho)
              circleStrokeColor: 0x404CAF50, // Borda verde semi-transparente
              circleStrokeWidth: 1.5,
            ),
          );
          _establishmentCircles.add(outerGlow);

          // Círculo médio pulsante para indicar que é clicável (efeito visual)
          final pulseCircle = await circleAnnotationManager!.create(
            CircleAnnotationOptions(
              geometry: Point(
                coordinates: Position(
                  establishment.longitude,
                  establishment.latitude,
                ),
              ),
              circleRadius: 15.0, // Círculo médio
              circleColor: 0x404CAF50, // Verde semi-transparente (pulsação)
              circleStrokeColor: 0x804CAF50, // Borda verde mais opaca
              circleStrokeWidth: 2.0,
            ),
          );
          _establishmentCircles.add(pulseCircle);

          // Círculo principal do marcador (verde sólido e destacado)
          final circle = await circleAnnotationManager!.create(
            CircleAnnotationOptions(
              geometry: Point(
                coordinates: Position(
                  establishment.longitude,
                  establishment.latitude,
                ),
              ),
              circleRadius: 14.0, // Raio um pouco maior para ser mais visível
              circleColor: 0xFF4CAF50, // Verde #4CAF50 sólido
              circleStrokeColor:
                  0xFFFFFFFF, // Borda branca grossa para destaque
              circleStrokeWidth:
                  4.0, // Borda mais grossa para parecer mais clicável
            ),
          );
          _establishmentCircles.add(circle);

          circlesCreated += 3; // Conta todos os três círculos
          debugPrint(
              '  ✅ Marcador criado para ${establishment.name} (com efeito clicável)');
        } catch (e) {
          debugPrint(
              '  ⚠️ Erro ao criar marcador para ${establishment.name}: $e');
        }
      }
      debugPrint('✅ $circlesCreated círculos criados com sucesso!');

      // Mapear IDs dos marcadores para estabelecimentos
      for (int i = 0;
          i < createdAnnotations.length && i < widget.establishments.length;
          i++) {
        final annotation = createdAnnotations[i];
        if (annotation != null) {
          try {
            final annotationId = annotation.id;
            if (annotationId != null) {
              _markerIdToEstablishment[annotationId] = widget.establishments[i];
              debugPrint(
                  '📌 Marcador mapeado $annotationId -> ${widget.establishments[i].name}');
            }
          } catch (e) {
            debugPrint('⚠️ Erro ao obter ID do marcador: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao criar marcadores: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _checkNearbyEstablishments() {
    // Se o modal estiver visível, não exibir estabelecimentos
    if (_isModalVisible) {
      debugPrint('Modal está visível, não exibindo estabelecimentos.');
      return;
    }

    // Se não houver estabelecimentos próximos, reseta o estado
    _nearbyEstablishment = null;
    _nearbyDistanceKm = null;

    // Adicione sua lógica para verificar estabelecimentos próximos aqui, se necessário
  }

  Future<void> _openRouteForEstablishment(Establishment establishment) async {
    try {
      final lat = establishment.latitude;
      final lng = establishment.longitude;
      final name = Uri.encodeComponent(establishment.name);

      try {
        final uri = Uri.parse('google.navigation:q=$lat,$lng');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        try {
          final uri = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
          );
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          try {
            final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${Translations.getText(context, 'errorOpeningNavigation')} $e',
                  ),
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
            content: Text(
              '${Translations.getText(context, 'errorGeneratingRoute')} $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MapboxService.mapboxAccessToken == 'YOUR_MAPBOX_ACCESS_TOKEN') {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
            child: Text(Translations.getText(context, 'configureMapboxToken'))),
      );
    }

    double centerLat = -23.5275;
    double centerLng = -46.7070;

    if (_userPosition != null) {
      centerLat = _userPosition!.latitude;
      centerLng = _userPosition!.longitude;
    } else if (widget.establishments.isNotEmpty) {
      centerLat =
          widget.establishments.map((e) => e.latitude).reduce((a, b) => a + b) /
              widget.establishments.length;
      centerLng = widget.establishments
              .map((e) => e.longitude)
              .reduce((a, b) => a + b) /
          widget.establishments.length;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            onPointerDown: (PointerDownEvent event) {
              // Usuário interagiu manualmente: não auto-centralizar mais
              _hasAutoCenteredOnUser = true;
              // Notificar interação com o mapa (para esconder UI flutuante)
              widget.onMapInteraction?.call();

              _pointerDownPosition = event.position;
              _isDragging = false;
              debugPrint(
                  '🖱️ PointerDown em (${event.position.dx}, ${event.position.dy})');
            },
            onPointerMove: (PointerMoveEvent event) {
              // Também notificar durante o movimento (pan/zoom)
              _hasAutoCenteredOnUser = true;
              widget.onMapInteraction?.call();

              if (_pointerDownPosition != null) {
                final distance =
                    (event.position - _pointerDownPosition!).distance;
                if (distance > 10) {
                  if (!_isDragging)
                    debugPrint(
                        '🖱️ Drag detectado (distância: ${distance.toStringAsFixed(1)}px)');
                  _isDragging = true;
                }
              }
            },
            onPointerUp: (PointerUpEvent event) async {
              if (!_isDragging && _pointerDownPosition != null) {
                debugPrint(
                    '🖱️ PointerUp detectado como TAP em (${event.position.dx}, ${event.position.dy})');
                final RenderBox? renderBox =
                    context.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  final localPosition = renderBox.globalToLocal(event.position);
                  if (renderBox.size.contains(localPosition)) {
                    final screenCoordinate = ScreenCoordinate(
                      x: localPosition.dx,
                      y: localPosition.dy,
                    );
                    await _handleMapTap(screenCoordinate);
                  }
                }
              } else if (_isDragging) {
                debugPrint('🖱️ PointerUp ignorado (foi um drag)');
              }

              _pointerDownPosition = null;
              _isDragging = false;

              // Adicionando um delay de 5 segundos antes de restaurar a interface
              await Future.delayed(const Duration(seconds: 3));

              // Chamar a função que restaura a UI
              widget.onMapInteractionEnd?.call();
            },
            onPointerCancel: (event) {
              widget.onMapInteractionEnd?.call();
              _pointerDownPosition = null;
              _isDragging = false;
            },
            behavior: HitTestBehavior.translucent,
            child: MapWidget(
              key: const ValueKey('mapWidget'),
              cameraOptions: CameraOptions(
                center: Point(
                  coordinates: Position(centerLng, centerLat),
                ),
                zoom: 10.5,
                pitch: 0.0,
                padding: MbxEdgeInsets(
                    top: 320.0, left: 0.0, bottom: 0.0, right: 0.0),
              ),
              styleUri: 'mapbox://styles/pratoseguro/cmkofllsb002u01qra9lm7cwl',
              textureView: true,
              onMapCreated: _onMapCreated,
            ),
          ),
        ),
        Positioned(
          bottom: 110,
          right: 20,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: centerOnUser,
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
        ),
      ],
    );
  }
}
