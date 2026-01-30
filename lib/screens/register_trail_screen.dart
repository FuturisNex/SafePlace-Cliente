import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/establishment.dart';
import '../models/trail_record.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../services/firebase_service.dart';
import '../services/gamification_service.dart';
import '../services/geocoding_service.dart';
import '../services/mapbox_service.dart';
import '../utils/translations.dart';

class RegisterTrailScreen extends StatefulWidget {
  const RegisterTrailScreen({super.key});

  @override
  State<RegisterTrailScreen> createState() => _RegisterTrailScreenState();
}

class _RegisterTrailScreenState extends State<RegisterTrailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _commentController = TextEditingController();
  final _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final Set<DietaryFilter> _selectedDietaryOptions = {};
  final List<File> _photos = [];

  double? _latitude;
  double? _longitude;
  bool _isSaving = false;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _commentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await MapboxService.getCurrentPosition();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Não foi possível obter sua localização atual.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Localização atual definida com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao obter localização: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _searchAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      return;
    }
    setState(() => _isLoadingLocation = true);
    try {
      final coordinates = await GeocodingService.getCoordinatesFromAddress(address);
      if (coordinates != null) {
        setState(() {
          _latitude = coordinates['latitude'];
          _longitude = coordinates['longitude'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Coordenadas obtidas para o endereço informado.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Endereço não encontrado. Verifique os dados informados.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar endereço: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images == null || images.isEmpty) {
        return;
      }
      setState(() {
        _photos
          ..clear()
          ..addAll(images.map((xfile) => File(xfile.path)));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar fotos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Establishment? _findExistingEstablishment(
    EstablishmentProvider provider,
    double latitude,
    double longitude,
  ) {
    Establishment? nearest;
    double minDistanceKm = double.infinity;

    for (final establishment in provider.establishments) {
      final distanceKm = MapboxService.calculateDistance(
        latitude,
        longitude,
        establishment.latitude,
        establishment.longitude,
      );
      if (distanceKm < minDistanceKm) {
        minDistanceKm = distanceKm;
        nearest = establishment;
      }
    }

    if (nearest != null && minDistanceKm <= 0.1) {
      return nearest;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final establishmentProvider = Provider.of<EstablishmentProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null || user.type != UserType.user) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.getText(context, 'pleaseLogin')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Defina a localização pelo GPS ou buscando o endereço.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDietaryOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um tipo de restrição atendida.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final address = _addressController.text.trim().isEmpty ? null : _addressController.text.trim();
      final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      final comment = _commentController.text.trim();
      final now = DateTime.now();
      final trailId = now.millisecondsSinceEpoch.toString();

      List<String> photoUrls = [];
      if (_photos.isNotEmpty) {
        photoUrls = await FirebaseService.uploadTrailPhotos(_photos, user.id, trailId);
      }

      final double lat = _latitude!;
      final double lng = _longitude!;

      Establishment? existing = _findExistingEstablishment(
        establishmentProvider,
        lat,
        lng,
      );

      bool isNewLocation = existing == null;
      Establishment targetEstablishment;
      String? referralId;

      if (existing != null) {
        targetEstablishment = existing;
      } else {
        // Novo local: salvar como indicação (referral) com origem 'trilha'
        // O estabelecimento será criado quando o admin aprovar
        referralId = await FirebaseService.saveTrailAsReferral(
          userId: user.id,
          name: name,
          category: 'Restaurante',
          latitude: lat,
          longitude: lng,
          address: address,
          phone: phone,
          dietaryOptions: _selectedDietaryOptions.toList(),
          comment: comment.isEmpty ? null : comment,
          photoUrls: photoUrls,
        );

        // Criar um estabelecimento temporário para o registro da trilha
        final tempEstablishmentId = 'pending_$referralId';
        targetEstablishment = Establishment(
          id: tempEstablishmentId,
          name: name,
          category: 'Restaurante',
          latitude: lat,
          longitude: lng,
          distance: 0.0,
          avatarUrl: '',
          difficultyLevel: DifficultyLevel.popular,
          dietaryOptions: _selectedDietaryOptions.toList(),
          isOpen: true,
          ownerId: null,
          address: address,
        );
      }

      final trail = TrailRecord(
        id: trailId,
        userId: user.id,
        establishmentId: targetEstablishment.id,
        name: targetEstablishment.name,
        latitude: targetEstablishment.latitude,
        longitude: targetEstablishment.longitude,
        address: targetEstablishment.address ?? address,
        dietaryOptions: _selectedDietaryOptions.toList(),
        comment: comment.isEmpty ? null : comment,
        phone: phone,
        photoUrls: photoUrls,
        isNewLocation: isNewLocation,
        createdAt: now,
      );

      await FirebaseService.saveTrailRecord(trail);

      try {
        await GamificationService.registerCheckIn(
          userId: user.id,
          establishmentId: targetEstablishment.id,
          establishmentName: targetEstablishment.name,
        );
        if (isNewLocation) {
          await GamificationService.addPoints(user.id, 40, 'trail_new_location_extra');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.orange,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trilha registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar trilha: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registre sua Trilha'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do local *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do local';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone do estabelecimento (opcional)',
                  hintText: '(41) 99624-3262',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  String formatted = digits;
                  if (digits.length >= 2) {
                    formatted = '(${digits.substring(0, 2)}';
                    if (digits.length >= 7) {
                      final body = digits.substring(2);
                      if (body.length > 5) {
                        formatted += ') ${body.substring(0, body.length - 4)}-${body.substring(body.length - 4)}';
                      } else {
                        formatted += ') $body';
                      }
                    } else {
                      final body = digits.substring(2);
                      if (body.isNotEmpty) {
                        formatted += ') $body';
                      } else {
                        formatted += ')';
                      }
                    }
                  }
                  if (formatted != value) {
                    _phoneController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: (value) {
                  final raw = value?.trim() ?? '';
                  if (raw.isEmpty) return null;
                  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length < 10 || digits.length > 11) {
                    return 'Informe um telefone válido com DDD ou deixe em branco';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      SizedBox(
                        width: 120,
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingLocation ? null : _searchAddress,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: const Text(
                            'Buscar',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 120,
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingLocation ? null : _useCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text(
                            'Usar GPS',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Localização: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Tipo de restrição atendida *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DietaryFilter.values.map((filter) {
                  final isSelected = _selectedDietaryOptions.contains(filter);
                  return FilterChip(
                    label: Text(filter.getLabel(context)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDietaryOptions.add(filter);
                        } else {
                          _selectedDietaryOptions.remove(filter);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickPhotos,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Adicionar fotos (opcional)'),
                  ),
                  const SizedBox(width: 12),
                  if (_photos.isNotEmpty)
                    Text(
                      '${_photos.length} foto(s) selecionada(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isSaving ? 'Salvando...' : 'Salvar Trilha',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
