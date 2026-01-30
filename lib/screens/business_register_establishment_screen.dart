import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../services/firebase_service.dart';
import '../services/cep_service.dart';
import '../services/geocoding_service.dart';
import '../models/establishment.dart';
import '../models/user.dart';
import '../models/business_plan.dart';
import '../theme/app_theme.dart';

class BusinessRegisterEstablishmentScreen extends StatefulWidget {
  final Establishment? existingEstablishment;

  const BusinessRegisterEstablishmentScreen({
    super.key,
    this.existingEstablishment,
  });

  @override
  State<BusinessRegisterEstablishmentScreen> createState() => _BusinessRegisterEstablishmentScreenState();
}

class _BusinessRegisterEstablishmentScreenState extends State<BusinessRegisterEstablishmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _cepController = TextEditingController();
  final _addressNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  List<File> _photos = [];
  final ImagePicker _picker = ImagePicker();
  Set<DietaryFilter> _selectedDietaryOptions = {};
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  TimeOfDay? _weekendOpeningTime;
  TimeOfDay? _weekendClosingTime;
  bool _hasDifferentWeekendHours = false;
  Set<int> _selectedDays = {}; // Dias da semana selecionados (0=domingo, 1=segunda, ..., 6=sábado)
  
  // Horários personalizados por dia da semana
  bool _hasCustomDailyHours = false;
  Map<int, TimeOfDay?> _dailyOpeningTimes = {};
  Map<int, TimeOfDay?> _dailyClosingTimes = {};
  Map<int, bool> _dailyClosed = {}; // Se o dia está fechado
  double? _latitude;
  double? _longitude;
  bool _isLoadingCep = false;
  bool _isLoadingGeocoding = false;
  bool _isLoading = false;
  
  // Dados de localização hierárquica (do CEP)
  String? _state;
  String? _city;
  String? _neighborhood;

  /// Converte UF para nome completo do estado
  String _normalizeState(String uf) {
    const stateMap = {
      'AC': 'Acre',
      'AL': 'Alagoas',
      'AP': 'Amapá',
      'AM': 'Amazonas',
      'BA': 'Bahia',
      'CE': 'Ceará',
      'DF': 'Distrito Federal',
      'ES': 'Espírito Santo',
      'GO': 'Goiás',
      'MA': 'Maranhão',
      'MT': 'Mato Grosso',
      'MS': 'Mato Grosso do Sul',
      'MG': 'Minas Gerais',
      'PA': 'Pará',
      'PB': 'Paraíba',
      'PR': 'Paraná',
      'PE': 'Pernambuco',
      'PI': 'Piauí',
      'RJ': 'Rio de Janeiro',
      'RN': 'Rio Grande do Norte',
      'RS': 'Rio Grande do Sul',
      'RO': 'Rondônia',
      'RR': 'Roraima',
      'SC': 'Santa Catarina',
      'SP': 'São Paulo',
      'SE': 'Sergipe',
      'TO': 'Tocantins',
    };
    return stateMap[uf.toUpperCase().trim()] ?? uf.trim();
  }

  String _billingCycleLabel(String billingCycle) {
    switch (billingCycle) {
      case 'quarterly':
        return 'Trimestral';
      case 'Annual':
        return 'Anual';
      default:
        return 'Personalizado';
    }
  }

  String _businessPlanStatusLabel(BusinessPlanStatus status) {
    switch (status) {
      case BusinessPlanStatus.active:
        return 'Ativo';
      case BusinessPlanStatus.pendingApproval:
        return 'Em análise';
      case BusinessPlanStatus.pendingPayment:
        return 'Aguardando pagamento';
      case BusinessPlanStatus.canceled:
        return 'Cancelado';
      case BusinessPlanStatus.none:
      default:
        return 'Inativo';
    }
  }

  Color _businessPlanStatusColor(BusinessPlanStatus status) {
    switch (status) {
      case BusinessPlanStatus.active:
        return Colors.green;
      case BusinessPlanStatus.pendingApproval:
        return Colors.orange;
      case BusinessPlanStatus.pendingPayment:
        return Colors.amber;
      case BusinessPlanStatus.canceled:
      case BusinessPlanStatus.none:
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();

    final est = widget.existingEstablishment;
    if (est != null) {
      _nameController.text = est.name;
      _categoryController.text = est.category;
      _addressController.text = est.address ?? '';
      _phoneController.text = est.phone ?? '';

      _latitude = est.latitude;
      _longitude = est.longitude;
      
      // Carregar dados de localização hierárquica
      _state = est.state;
      _city = est.city;
      _neighborhood = est.neighborhood;

      _selectedDietaryOptions = est.dietaryOptions.toSet();
      _selectedDays = est.openingDays?.toSet() ?? {};

      // Horários de semana
      if (est.openingTime != null && est.openingTime!.contains(':')) {
        final parts = est.openingTime!.split(':');
        _openingTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      if (est.closingTime != null && est.closingTime!.contains(':')) {
        final parts = est.closingTime!.split(':');
        _closingTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 18,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }

      // Horários de fim de semana
      if (est.weekendOpeningTime != null && est.weekendOpeningTime!.contains(':')) {
        final parts = est.weekendOpeningTime!.split(':');
        _weekendOpeningTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      if (est.weekendClosingTime != null && est.weekendClosingTime!.contains(':')) {
        final parts = est.weekendClosingTime!.split(':');
        _weekendClosingTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 17,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }

      _hasDifferentWeekendHours =
          est.weekendOpeningTime != null || est.weekendClosingTime != null;
      
      // Carregar horários personalizados por dia
      if (est.weeklySchedule != null && est.weeklySchedule!.hasCustomSchedule) {
        _hasCustomDailyHours = true;
        for (final entry in est.weeklySchedule!.schedule.entries) {
          final dayIndex = entry.key;
          final schedule = entry.value;
          _dailyClosed[dayIndex] = schedule.isClosed;
          if (schedule.openingTime != null && schedule.openingTime!.contains(':')) {
            final parts = schedule.openingTime!.split(':');
            _dailyOpeningTimes[dayIndex] = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 9,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
          if (schedule.closingTime != null && schedule.closingTime!.contains(':')) {
            final parts = schedule.closingTime!.split(':');
            _dailyClosingTimes[dayIndex] = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 18,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _cepController.dispose();
    _addressNumberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _searchCep() async {
    final cep = _cepController.text.trim();
    if (cep.isEmpty || cep.replaceAll(RegExp(r'[^0-9]'), '').length != 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, informe um CEP válido (8 dígitos)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    setState(() => _isLoadingCep = true);
    
    try {
      final addressData = await CepService.getAddressByCep(cep);
      
      if (addressData != null) {
        // Atualizar endereço com número se fornecido
        final number = _addressNumberController.text.trim();
        final formattedAddress = CepService.formatAddress(addressData, number.isNotEmpty ? number : null);
        
        // Salvar dados de localização hierárquica para uso posterior
        setState(() {
          _addressController.text = formattedAddress;
          _state = _normalizeState(addressData['state'] ?? '');
          _city = addressData['city']?.trim();
          _neighborhood = addressData['neighborhood']?.trim();
        });
        
        // Fazer geocoding do endereço para obter lat/long
        setState(() => _isLoadingGeocoding = true);
        final coordinates = await GeocodingService.getCoordinatesFromAddress(formattedAddress);
        
        if (coordinates != null) {
          setState(() {
            _latitude = coordinates['latitude'];
            _longitude = coordinates['longitude'];
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Endereço encontrado e coordenadas obtidas! ✅'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Endereço encontrado, mas não foi possível obter coordenadas. Você pode informar manualmente.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CEP não encontrado. Verifique o CEP informado.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar CEP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCep = false;
          _isLoadingGeocoding = false;
        });
      }
    }
  }
  
  Future<void> _updateGeocoding() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    
    setState(() => _isLoadingGeocoding = true);
    
    try {
      final coordinates = await GeocodingService.getCoordinatesFromAddress(address);
      
      if (coordinates != null) {
        setState(() {
          _latitude = coordinates['latitude'];
          _longitude = coordinates['longitude'];
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coordenadas atualizadas! ✅'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível obter coordenadas do endereço.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar coordenadas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingGeocoding = false);
      }
    }
  }
  
  Future<void> _selectOpeningTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _openingTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _openingTime = picked;
      });
    }
  }
  
  Future<void> _selectClosingTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _closingTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _closingTime = picked;
      });
    }
  }

  Future<void> _selectWeekendOpeningTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _weekendOpeningTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _weekendOpeningTime = picked;
      });
    }
  }

  Future<void> _selectWeekendClosingTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _weekendClosingTime ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _weekendClosingTime = picked;
      });
    }
  }

  bool _hasActivePlan() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final plan = authProvider.currentBusinessPlan;
    return plan != null && plan.status == BusinessPlanStatus.active;
  }

  void _showUpgradeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_camera,
                size: 40,
                color: Colors.amber.shade700,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Destaque seu estabelecimento!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Adicione fotos do seu estabelecimento para atrair mais clientes. Fotos são exclusivas para assinantes dos planos pagos.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                children: [
                  _buildPlanFeature(Icons.photo, 'Plano Inicial', '1 foto'),
                  const SizedBox(height: 8),
                  _buildPlanFeature(Icons.photo_library, 'Plano Intermediário', 'até 5 fotos'),
                  const SizedBox(height: 8),
                  _buildPlanFeature(Icons.collections, 'Plano Profissional', 'até 10 fotos'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Ver Planos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Continuar sem foto',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanFeature(IconData icon, String plan, String feature) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            plan,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          feature,
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    // Verificar se tem plano ativo
    if (!_hasActivePlan()) {
      _showUpgradeModal();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final plan = authProvider.currentBusinessPlan;
    final int maxPhotosPerEstablishment = plan!.planType.maxEstablishmentPhotos;

    if (_photos.length >= maxPhotosPerEstablishment) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Seu plano atual permite apenas ${maxPhotosPerEstablishment == 1 ? "1 foto" : "$maxPhotosPerEstablishment fotos"} por estabelecimento.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    // Verificar se tem plano ativo
    if (!_hasActivePlan()) {
      _showUpgradeModal();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final plan = authProvider.currentBusinessPlan;
    final int maxPhotosPerEstablishment = plan!.planType.maxEstablishmentPhotos;

    if (_photos.length >= maxPhotosPerEstablishment) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Seu plano atual permite apenas ${maxPhotosPerEstablishment == 1 ? "1 foto" : "$maxPhotosPerEstablishment fotos"} por estabelecimento.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao capturar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar imagem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null || user.type != UserType.business) {
        throw Exception('Usuário não autenticado como empresa');
      }

      // Salvar Provider antes de qualquer await
      final establishmentProvider = Provider.of<EstablishmentProvider>(context, listen: false);

      // As fotos serão enviadas após obtermos o ID real do estabelecimento
      String avatarUrl = '';
      List<String> photoUrls = [];

      // Validar coordenadas
      if (_latitude == null || _longitude == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, busque o endereço pelo CEP para obter as coordenadas automaticamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Validar telefone
      final rawPhone = _phoneController.text.trim();
      final digitsOnly = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.isEmpty || digitsOnly.length < 10 || digitsOnly.length > 11) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, informe um telefone válido com DDD.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      
      // Validar dias da semana
      if (_selectedDays.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, selecione pelo menos um dia de funcionamento.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      
      // Validar horários
      if (_openingTime == null || _closingTime == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, informe o horário de funcionamento.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      
      // Validar horários de fim de semana se checkbox marcado
      if (_hasDifferentWeekendHours && (_weekendOpeningTime == null || _weekendClosingTime == null)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, informe o horário de funcionamento do fim de semana.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      
      // Calcular isOpen baseado no horário e dias
      final weekendOpeningStr = _hasDifferentWeekendHours && _weekendOpeningTime != null
          ? '${_weekendOpeningTime!.hour.toString().padLeft(2, '0')}:${_weekendOpeningTime!.minute.toString().padLeft(2, '0')}'
          : null;
      final weekendClosingStr = _hasDifferentWeekendHours && _weekendClosingTime != null
          ? '${_weekendClosingTime!.hour.toString().padLeft(2, '0')}:${_weekendClosingTime!.minute.toString().padLeft(2, '0')}'
          : null;
      
      // Construir weeklySchedule se houver horários personalizados
      WeeklySchedule? weeklySchedule;
      if (_hasCustomDailyHours) {
        final scheduleMap = <int, DaySchedule>{};
        for (int i = 0; i < 7; i++) {
          final isClosed = _dailyClosed[i] ?? false;
          final openTime = _dailyOpeningTimes[i];
          final closeTime = _dailyClosingTimes[i];
          
          scheduleMap[i] = DaySchedule(
            isClosed: isClosed,
            openingTime: !isClosed && openTime != null
                ? '${openTime.hour.toString().padLeft(2, '0')}:${openTime.minute.toString().padLeft(2, '0')}'
                : null,
            closingTime: !isClosed && closeTime != null
                ? '${closeTime.hour.toString().padLeft(2, '0')}:${closeTime.minute.toString().padLeft(2, '0')}'
                : null,
          );
        }
        weeklySchedule = WeeklySchedule(schedule: scheduleMap);
      }
          
      final calculatedIsOpen = Establishment.calculateIsOpen(
        '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}',
        '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}',
        _selectedDays.toList(),
        weekendOpeningStr,
        weekendClosingStr,
      );

      final bool isEditing = widget.existingEstablishment != null;

      if (isEditing) {
        // Atualizar estabelecimento existente (sem mexer nas fotos aqui)
        final existing = widget.existingEstablishment!;

        final updated = Establishment(
          id: existing.id,
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          latitude: _latitude!,
          longitude: _longitude!,
          distance: existing.distance,
          avatarUrl: existing.avatarUrl,
          photoUrls: existing.photoUrls,
          difficultyLevel: existing.difficultyLevel,
          dietaryOptions: _selectedDietaryOptions.toList(),
          isOpen: calculatedIsOpen,
          ownerId: existing.ownerId ?? user.id,
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          openingTime: '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}',
          closingTime: '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}',
          weekendOpeningTime: weekendOpeningStr,
          weekendClosingTime: weekendClosingStr,
          openingDays: _selectedDays.toList(),
          weeklySchedule: weeklySchedule,
          premiumUntil: existing.premiumUntil,
          certificationStatus: existing.certificationStatus,
          lastInspectionDate: existing.lastInspectionDate,
          lastInspectionStatus: existing.lastInspectionStatus,
          isBoosted: existing.isBoosted,
          boostExpiresAt: existing.boostExpiresAt,
          planType: existing.planType,
          state: existing.state,
          city: existing.city,
          neighborhood: existing.neighborhood,
        );

        await FirebaseService.updateEstablishment(existing.id, updated.toJson());
        establishmentProvider.addEstablishment(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estabelecimento atualizado com sucesso! ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        }

        return;
      }

      // Criação de novo estabelecimento
      var establishment = Establishment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        distance: 0.0,
        avatarUrl: avatarUrl,
        photoUrls: photoUrls,
        difficultyLevel: DifficultyLevel.popular, // Valor padrão - será definido pelo admin depois
        dietaryOptions: _selectedDietaryOptions.toList(),
        isOpen: calculatedIsOpen,
        ownerId: user.id,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        openingTime: '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}',
        closingTime: '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}',
        weekendOpeningTime: weekendOpeningStr,
        weekendClosingTime: weekendClosingStr,
        openingDays: _selectedDays.toList(),
        weeklySchedule: weeklySchedule,
        // Dados de localização hierárquica (do CEP)
        state: _state,
        city: _city,
        neighborhood: _neighborhood,
      );

      // Salvar no Firestore (com timeout)
      String? savedId;
      try {
        savedId = await FirebaseService.saveEstablishment(establishment).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Timeout ao salvar estabelecimento. Verifique sua conexão.');
          },
        );
        
        // Atualizar o ID do estabelecimento com o ID retornado pelo Firestore
        if (savedId != null && savedId != establishment.id) {
          establishment = Establishment(
            id: savedId,
            name: establishment.name,
            category: establishment.category,
            latitude: establishment.latitude,
            longitude: establishment.longitude,
            distance: establishment.distance,
            avatarUrl: establishment.avatarUrl,
            photoUrls: establishment.photoUrls,
            difficultyLevel: establishment.difficultyLevel,
            dietaryOptions: establishment.dietaryOptions,
            isOpen: establishment.isOpen,
            ownerId: establishment.ownerId,
            address: establishment.address,
            phone: establishment.phone,
            openingTime: establishment.openingTime,
            closingTime: establishment.closingTime,
            openingDays: establishment.openingDays,
            weeklySchedule: establishment.weeklySchedule,
            state: establishment.state,
            city: establishment.city,
            neighborhood: establishment.neighborhood,
          );
        }

        // Upload das fotos após obter o ID real, respeitando o limite do plano
        if (_photos.isNotEmpty && savedId != null) {
          try {
            final planForPhotos = authProvider.currentBusinessPlan;
            int maxPhotosPerEstablishment;
            if (planForPhotos != null && planForPhotos.status == BusinessPlanStatus.active) {
              maxPhotosPerEstablishment = planForPhotos.planType.maxEstablishmentPhotos;
            } else {
              maxPhotosPerEstablishment = 1;
            }

            final limitedPhotos = _photos.take(maxPhotosPerEstablishment).toList();

            photoUrls = await FirebaseService.uploadEstablishmentPhotos(limitedPhotos, savedId);
            await FirebaseService.updateEstablishmentPhotos(savedId, photoUrls).timeout(
              const Duration(seconds: 10),
            );

            avatarUrl = photoUrls.isNotEmpty ? photoUrls.first : '';

            establishment = Establishment(
              id: establishment.id,
              name: establishment.name,
              category: establishment.category,
              latitude: establishment.latitude,
              longitude: establishment.longitude,
              distance: establishment.distance,
              avatarUrl: avatarUrl,
              photoUrls: photoUrls,
              difficultyLevel: establishment.difficultyLevel,
              dietaryOptions: establishment.dietaryOptions,
              isOpen: establishment.isOpen,
              ownerId: establishment.ownerId,
              address: establishment.address,
              phone: establishment.phone,
              openingTime: establishment.openingTime,
              closingTime: establishment.closingTime,
              openingDays: establishment.openingDays,
              state: establishment.state,
              city: establishment.city,
              neighborhood: establishment.neighborhood,
            );
          } catch (e) {
            debugPrint('⚠️ Erro ao enviar/atualizar fotos do estabelecimento (não crítico): $e');
          }
        }
        
        // Adicionar imediatamente à lista local (sem esperar reload)
        establishmentProvider.addEstablishment(establishment);
        
        // Recarregar estabelecimentos no provider (em background, não crítico)
        try {
          establishmentProvider.reloadEstablishments().timeout(
            const Duration(seconds: 5),
          ).catchError((e) {
            debugPrint('⚠️ Erro ao recarregar estabelecimentos (não crítico): $e');
          });
        } catch (e) {
          debugPrint('⚠️ Erro ao recarregar estabelecimentos (não crítico): $e');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estabelecimento cadastrado com sucesso! ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        }
      } on TimeoutException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Timeout: ${e.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: $e'),
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final plan = authProvider.currentBusinessPlan;
    final int maxPhotosPerEstablishment;
    final bool hasActiveBusinessPlan =
        plan != null && plan.status == BusinessPlanStatus.active;

    if (hasActiveBusinessPlan) {
      maxPhotosPerEstablishment = plan.planType.maxEstablishmentPhotos;
    } else {
      maxPhotosPerEstablishment = 1;
    }

    final isEditing = widget.existingEstablishment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Estabelecimento' : 'Cadastrar Estabelecimento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upload de foto
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _photos.isNotEmpty ? FileImage(_photos.first) : null,
                      child: _photos.isEmpty
                          ? const Icon(Icons.restaurant, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: FloatingActionButton.small(
                        onPressed: _showImageSourceDialog,
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  hasActiveBusinessPlan
                      ? 'Fotos selecionadas: ${_photos.length}/$maxPhotosPerEstablishment por estabelecimento.'
                      : 'Plano gratuito: ${_photos.length}/1 foto selecionada. Planos pagos liberam mais fotos.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Dica: use imagens quadradas (ex: 800x800px) em boa resolução para melhor resultado.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final file = _photos[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              file,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _photos.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (isEditing && authProvider.user != null) ...[
                FutureBuilder<BusinessPlanSubscription?>(
                  future: FirebaseService.getCurrentBusinessPlanForEstablishment(
                    ownerId: authProvider.user!.id,
                    establishmentId: widget.existingEstablishment!.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final establishmentPlan = snapshot.data;

                    if (establishmentPlan == null ||
                        establishmentPlan.status == BusinessPlanStatus.canceled ||
                        establishmentPlan.status == BusinessPlanStatus.none) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Este estabelecimento ainda não possui um plano de divulgação contratado.',
                          style: TextStyle(fontSize: 12),
                        ),
                      );
                    }

                    final billingLabel = _billingCycleLabel(establishmentPlan.billingCycle);
                    final statusColor = _businessPlanStatusColor(establishmentPlan.status);
                    final statusLabel = _businessPlanStatusLabel(establishmentPlan.status);

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              establishmentPlan.planType.icon,
                              size: 18,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Platform.isIOS 
                                      ? 'Nível deste estabelecimento: ${establishmentPlan.planType.title}'
                                      : 'Plano deste estabelecimento: ${establishmentPlan.planType.title}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ciclo de cobrança: $billingLabel',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                if (establishmentPlan.validUntil != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Válido até ${DateFormat('dd/MM/yyyy').format(establishmentPlan.validUntil!)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Estabelecimento *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Categoria
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoria *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Restaurante, Padaria, Café...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe a categoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Telefone da empresa
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone da empresa *',
                  border: OutlineInputBorder(),
                  hintText: '(41) 99624-3262',
                ),
                onChanged: (value) {
                  // Aplicar máscara simples: (DD) 9XXXX-XXXX ou (DD) XXXX-XXXX
                  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  String formatted = digits;
                  if (digits.length >= 2) {
                    formatted = '(${digits.substring(0, 2)}';
                    if (digits.length >= 7) {
                      // Celular: (DD) 9XXXX-XXXX ou fixo: (DD) XXXX-XXXX
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
                  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) {
                    return 'Por favor, informe o telefone da empresa';
                  }
                  if (digits.length < 10 || digits.length > 11) {
                    return 'Informe um telefone válido com DDD';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // CEP
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'CEP *',
                        border: const OutlineInputBorder(),
                        hintText: '00000-000',
                        suffixIcon: _isLoadingCep
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _searchCep,
                              ),
                      ),
                      onChanged: (value) {
                        // Formatar CEP automaticamente
                        final cleanCep = value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (cleanCep.length <= 8) {
                          String formatted = cleanCep;
                          if (cleanCep.length > 5) {
                            formatted = '${cleanCep.substring(0, 5)}-${cleanCep.substring(5)}';
                          }
                          if (formatted != value) {
                            _cepController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        }
                        
                        // Buscar automaticamente quando tiver 8 dígitos
                        if (cleanCep.length == 8) {
                          _searchCep();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _addressNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Número',
                        border: OutlineInputBorder(),
                        hintText: '123',
                      ),
                      onChanged: (value) {
                        // Atualizar endereço quando número mudar
                        if (_addressController.text.isNotEmpty && value.isNotEmpty) {
                          // Reformatar endereço com novo número
                          final cep = _cepController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
                          if (cep.length == 8) {
                            // Buscar CEP novamente para atualizar com o número
                            _searchCep();
                          } else {
                            // Se não tem CEP válido, apenas atualizar geocoding
                            _updateGeocoding();
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Endereço (preenchido automaticamente)
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Endereço *',
                  border: const OutlineInputBorder(),
                  hintText: 'Será preenchido automaticamente pelo CEP',
                  suffixIcon: _isLoadingGeocoding
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _updateGeocoding,
                          tooltip: 'Atualizar coordenadas',
                        ),
                ),
                maxLines: 2,
                readOnly: true,
              ),
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Coordenadas: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              
              // Dias da semana
              const Text(
                'Dias de Funcionamento *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDayChip(0, 'Dom'),
                  _buildDayChip(1, 'Seg'),
                  _buildDayChip(2, 'Ter'),
                  _buildDayChip(3, 'Qua'),
                  _buildDayChip(4, 'Qui'),
                  _buildDayChip(5, 'Sex'),
                  _buildDayChip(6, 'Sáb'),
                ],
              ),
              const SizedBox(height: 16),
              
              // Horário de funcionamento
              const Text(
                'Horário de Funcionamento *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectOpeningTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Abertura',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  _openingTime != null
                                      ? '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Selecione',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectClosingTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fechamento',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  _closingTime != null
                                      ? '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Selecione',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Checkbox para horário diferente no fim de semana
              CheckboxListTile(
                title: const Text(
                  'Horário diferente no fim de semana?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Marque se seu estabelecimento funciona com horários diferentes aos sábados e domingos',
                  style: TextStyle(fontSize: 12),
                ),
                value: _hasDifferentWeekendHours,
                activeColor: AppTheme.primaryGreen,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _hasDifferentWeekendHours = value ?? false;
                  });
                },
              ),
              
              // Campos de horário do fim de semana (condicional)
              if (_hasDifferentWeekendHours) ...[
                const SizedBox(height: 8),
                const Text(
                  'Horário de Fim de Semana (Sáb/Dom) *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectWeekendOpeningTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryGreen),
                            borderRadius: BorderRadius.circular(8),
                            color: AppTheme.primaryGreen.withOpacity(0.05),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Abertura',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    _weekendOpeningTime != null
                                        ? '${_weekendOpeningTime!.hour.toString().padLeft(2, '0')}:${_weekendOpeningTime!.minute.toString().padLeft(2, '0')}'
                                        : 'Selecione',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const Icon(Icons.access_time, color: AppTheme.primaryGreen),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectWeekendClosingTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryGreen),
                            borderRadius: BorderRadius.circular(8),
                            color: AppTheme.primaryGreen.withOpacity(0.05),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fechamento',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    _weekendClosingTime != null
                                        ? '${_weekendClosingTime!.hour.toString().padLeft(2, '0')}:${_weekendClosingTime!.minute.toString().padLeft(2, '0')}'
                                        : 'Selecione',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const Icon(Icons.access_time, color: AppTheme.primaryGreen),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              
              // Opção de horários personalizados por dia
              CheckboxListTile(
                title: const Text(
                  'Horário diferente para cada dia?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Configure horários específicos para cada dia da semana',
                  style: TextStyle(fontSize: 12),
                ),
                value: _hasCustomDailyHours,
                activeColor: AppTheme.primaryGreen,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _hasCustomDailyHours = value ?? false;
                    if (_hasCustomDailyHours && _dailyOpeningTimes.isEmpty) {
                      // Inicializar com horário padrão para todos os dias
                      for (int i = 0; i < 7; i++) {
                        _dailyOpeningTimes[i] = _openingTime ?? const TimeOfDay(hour: 9, minute: 0);
                        _dailyClosingTimes[i] = _closingTime ?? const TimeOfDay(hour: 18, minute: 0);
                        _dailyClosed[i] = !_selectedDays.contains(i);
                      }
                    }
                  });
                },
              ),
              
              // Campos de horário por dia (condicional)
              if (_hasCustomDailyHours) ...[
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
                        'Horários por dia da semana:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(7, (dayIndex) {
                        final dayNames = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
                        final isClosed = _dailyClosed[dayIndex] ?? false;
                        final openTime = _dailyOpeningTimes[dayIndex];
                        final closeTime = _dailyClosingTimes[dayIndex];
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  dayNames[dayIndex],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isClosed ? Colors.grey : Colors.black87,
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: !isClosed,
                                activeColor: AppTheme.primaryGreen,
                                onChanged: (value) {
                                  setState(() {
                                    _dailyClosed[dayIndex] = !(value ?? true);
                                  });
                                },
                              ),
                              if (!isClosed) ...[
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: openTime ?? const TimeOfDay(hour: 9, minute: 0),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _dailyOpeningTimes[dayIndex] = time;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        openTime != null
                                            ? '${openTime.hour.toString().padLeft(2, '0')}:${openTime.minute.toString().padLeft(2, '0')}'
                                            : '--:--',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text('-'),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: closeTime ?? const TimeOfDay(hour: 18, minute: 0),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _dailyClosingTimes[dayIndex] = time;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        closeTime != null
                                            ? '${closeTime.hour.toString().padLeft(2, '0')}:${closeTime.minute.toString().padLeft(2, '0')}'
                                            : '--:--',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                              ] else
                                const Expanded(
                                  child: Text(
                                    'Fechado',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              
              // Opções dietéticas
              const Text(
                'Opções Dietéticas Disponíveis:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DietaryFilter.values.map((filter) {
                  return FilterChip(
                    label: Text(filter.getLabel(context)),
                    selected: _selectedDietaryOptions.contains(filter),
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
              
              // Botão de cadastrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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
                          'Cadastrar Estabelecimento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              // Espaço extra para garantir que o botão não fique atrás da barra de navegação
              SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDayChip(int day, String label) {
    final isSelected = _selectedDays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDays.add(day);
          } else {
            _selectedDays.remove(day);
          }
        });
      },
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green,
    );
  }
}

