import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/menu_item.dart'; // Inclui WeekDay
import '../models/establishment.dart';
import '../services/firebase_service.dart';

class BusinessEditMenuItemScreen extends StatefulWidget {
  final String establishmentId;
  final MenuItem? existingItem;

  const BusinessEditMenuItemScreen({
    super.key,
    required this.establishmentId,
    this.existingItem,
  });

  @override
  State<BusinessEditMenuItemScreen> createState() => _BusinessEditMenuItemScreenState();
}

class _BusinessEditMenuItemScreenState extends State<BusinessEditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String _initialImageUrl = '';
  bool _isAvailable = true;
  Set<DietaryFilter> _selectedDietaryOptions = {};
  bool _isSaving = false;
  
  // Dias da semana disponíveis (null = todos os dias)
  bool _hasCustomDays = false;
  Set<int> _selectedDays = {0, 1, 2, 3, 4, 5, 6}; // Todos os dias por padrão

  @override
  void initState() {
    super.initState();

    final existing = widget.existingItem;
    if (existing != null) {
      _nameController.text = existing.name;
      _descriptionController.text = existing.description ?? '';
      _priceController.text = existing.price.toStringAsFixed(2).replaceAll('.', ',');
      _isAvailable = existing.isAvailable;
      _selectedDietaryOptions = existing.dietaryOptions.toSet();
      _initialImageUrl = existing.imageUrl;
      
      // Carregar dias disponíveis
      if (existing.availableDays != null && existing.availableDays!.isNotEmpty) {
        _hasCustomDays = true;
        _selectedDays = existing.availableDays!.toSet();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      final rawPrice = _priceController.text.trim().replaceAll('.', '').replaceAll(',', '.');
      final price = double.tryParse(rawPrice) ?? 0.0;

      if (price <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Informe um preço válido maior que zero.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      String imageUrl = _initialImageUrl;

      if (_imageFile != null) {
        final existing = widget.existingItem;
        final dishId = existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await FirebaseService.uploadDishImage(
          _imageFile!,
          widget.establishmentId,
          dishId,
        );
      }

      final bool isEditing = widget.existingItem != null;

      // Dias disponíveis (null se todos os dias)
      List<int>? availableDays;
      if (_hasCustomDays) {
        availableDays = _selectedDays.toList()..sort();
      }

      if (isEditing) {
        final existing = widget.existingItem!;
        final updated = MenuItem(
          id: existing.id,
          establishmentId: widget.establishmentId,
          name: name,
          description: description,
          price: price,
          dietaryOptions: _selectedDietaryOptions.toList(),
          isAvailable: _isAvailable,
          imageUrl: imageUrl,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
          availableDays: availableDays,
        );

        await FirebaseService.updateMenuItem(
          widget.establishmentId,
          existing.id,
          updated.toJson(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prato atualizado com sucesso! ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        final item = MenuItem(
          id: tempId,
          establishmentId: widget.establishmentId,
          name: name,
          description: description,
          price: price,
          dietaryOptions: _selectedDietaryOptions.toList(),
          isAvailable: _isAvailable,
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          availableDays: availableDays,
        );

        await FirebaseService.createMenuItem(widget.establishmentId, item);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prato cadastrado com sucesso! ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar prato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar prato' : 'Adicionar prato'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _imageFile != null
                          ? Image.file(
                              _imageFile!,
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                            )
                          : (_initialImageUrl.isNotEmpty
                              ? Image.network(
                                  _initialImageUrl,
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 160,
                                    height: 160,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.restaurant_menu, size: 64),
                                  ),
                                )
                              : Container(
                                  width: 160,
                                  height: 160,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.restaurant_menu, size: 64),
                                )),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _isSaving ? null : _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Selecionar imagem do prato'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do prato',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do prato';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$)',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Disponível no cardápio'),
                value: _isAvailable,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _isAvailable = value;
                        });
                      },
              ),
              const SizedBox(height: 8),
              
              // Disponibilidade por dia da semana
              SwitchListTile(
                title: const Text('Disponível apenas em dias específicos'),
                subtitle: _hasCustomDays 
                    ? Text(
                        _selectedDays.isEmpty 
                            ? 'Nenhum dia selecionado'
                            : (_selectedDays.toList()..sort())
                                .map((d) => WeekDay.values[d].shortLabel)
                                .join(', '),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      )
                    : null,
                value: _hasCustomDays,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _hasCustomDays = value;
                          if (!value) {
                            _selectedDays = {0, 1, 2, 3, 4, 5, 6};
                          }
                        });
                      },
              ),
              
              if (_hasCustomDays) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selecione os dias disponíveis:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(7, (index) {
                          final isSelected = _selectedDays.contains(index);
                          return FilterChip(
                            label: Text(WeekDay.values[index].shortLabel),
                            selected: isSelected,
                            onSelected: _isSaving
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value) {
                                        _selectedDays.add(index);
                                      } else {
                                        _selectedDays.remove(index);
                                      }
                                    });
                                  },
                            selectedColor: Colors.green.shade100,
                            checkmarkColor: Colors.green.shade700,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              const Text(
                'Opções dietéticas deste prato',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: -8,
                children: DietaryFilter.values.map((filter) {
                  final selected = _selectedDietaryOptions.contains(filter);
                  return FilterChip(
                    label: Text(filter.getLabel(context)),
                    selected: selected,
                    onSelected: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              if (value) {
                                _selectedDietaryOptions.add(filter);
                              } else {
                                _selectedDietaryOptions.remove(filter);
                              }
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: Icon(isEditing ? Icons.save : Icons.check),
                  label: Text(isEditing ? 'Salvar alterações' : 'Cadastrar prato'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
