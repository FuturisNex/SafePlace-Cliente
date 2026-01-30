import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/establishment.dart';
import '../services/referral_service.dart';
import '../services/geocoding_service.dart';
import '../utils/translations.dart';

class ReferEstablishmentScreen extends StatefulWidget {
  const ReferEstablishmentScreen({super.key});

  @override
  State<ReferEstablishmentScreen> createState() => _ReferEstablishmentScreenState();
}

class _ReferEstablishmentScreenState extends State<ReferEstablishmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCategory = 'Restaurante';
  Set<DietaryFilter> _selectedDietaryOptions = {};
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  final List<String> _categories = [
    'Restaurante',
    'Café',
    'Padaria',
    'Confeitaria',
    'Hotel',
    'Pousada',
    'Mercado',
    'Farmácia',
    'Outro',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final coordinates = await GeocodingService.getCoordinatesFromAddress(address);
      if (coordinates != null) {
        setState(() {
          _latitude = coordinates['latitude'];
          _longitude = coordinates['longitude'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Endereço encontrado! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Endereço não encontrado. Verifique o endereço.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar endereço: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReferral() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, busque o endereço primeiro para obter as coordenadas.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.getText(context, 'pleaseLogin')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final establishment = Establishment(
        id: '', // Será gerado pelo Firestore
        name: _nameController.text.trim(),
        category: _selectedCategory,
        latitude: _latitude!,
        longitude: _longitude!,
        distance: 0,
        avatarUrl: '',
        difficultyLevel: DifficultyLevel.intermediate,
        dietaryOptions: _selectedDietaryOptions.toList(),
        isOpen: true,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      await ReferralService.referEstablishment(
        userId: user.id,
        establishment: establishment,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Recarregar dados do usuário
      await authProvider.reloadUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indicação enviada com sucesso! +50 pontos 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao indicar estabelecimento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indicar Novo Local'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajude outros usuários encontrando novos locais seguros!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Você ganhará 50 pontos por cada indicação aprovada! 🎉',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Estabelecimento *',
                  hintText: 'Ex: Restaurante Vegano',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o nome do estabelecimento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Telefone (opcional)
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
              // Categoria
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Endereço
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço Completo *',
                        hintText: 'Ex: Rua das Flores, 123 - São Paulo, SP',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, informe o endereço';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _searchAddress,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Buscar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  '✅ Coordenadas encontradas: $_latitude, $_longitude',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Opções alimentares
              Text(
                'Opções Alimentares Disponíveis *',
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
              if (_selectedDietaryOptions.isEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Selecione pelo menos uma opção',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Observações
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Informações adicionais sobre o estabelecimento...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // Botão enviar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReferral,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enviar Indicação',
                          style: TextStyle(fontSize: 16),
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


