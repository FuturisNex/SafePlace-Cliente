import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../models/establishment.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';

/// Tela de criação de novo itinerário de viagem
class CreateTripScreen extends StatefulWidget {
  final String? initialDestination;
  
  const CreateTripScreen({super.key, this.initialDestination});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 10));
  List<String> _destinations = [];
  final TextEditingController _destinationController = TextEditingController();
  double? _budget;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      _destinations.add(widget.initialDestination!);
      _nameController.text = 'Viagem para ${widget.initialDestination}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Novo Itinerário',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(_currentStep == 2 ? 'Criar Viagem' : 'Próximo'),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(
                        'Voltar',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Informações Básicas'),
              subtitle: const Text('Nome e descrição da viagem'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildBasicInfoStep(),
            ),
            Step(
              title: const Text('Destinos e Datas'),
              subtitle: const Text('Para onde e quando'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildDestinationsStep(),
            ),
            Step(
              title: const Text('Orçamento'),
              subtitle: const Text('Planejamento financeiro'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: _buildBudgetStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nome da viagem *',
            hintText: 'Ex: Férias em Curitiba',
            prefixIcon: const Icon(Icons.luggage),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, dê um nome à sua viagem';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Descrição (opcional)',
            hintText: 'Conte um pouco sobre essa viagem...',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 50),
              child: Icon(Icons.notes),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Dicas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dica: Escolha um nome memorável para encontrar facilmente depois!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Destinos
        const Text(
          'Destinos',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _destinationController,
                decoration: InputDecoration(
                  hintText: 'Adicionar cidade...',
                  prefixIcon: const Icon(Icons.location_city),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: _addDestination,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _addDestination(_destinationController.text),
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 32),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de destinos
        if (_destinations.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _destinations.asMap().entries.map((entry) {
              final index = entry.key;
              final dest = entry.value;
              return Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0) ...[
                      const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                    ],
                    Text(dest),
                  ],
                ),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeDestination(index),
                backgroundColor: Colors.teal.shade50,
                labelStyle: TextStyle(color: Colors.teal.shade700),
              );
            }).toList(),
          ),
        
        // Sugestões de cidades com estabelecimentos
        const SizedBox(height: 20),
        const Text(
          'Cidades com locais seguros:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Consumer<EstablishmentProvider>(
          builder: (context, provider, _) {
            final cities = provider.establishments
                .map((e) => e.city)
                .where((c) => c != null && c.isNotEmpty)
                .cast<String>()
                .toSet()
                .toList()
              ..sort();
            
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cities.take(6).map((city) {
                final isSelected = _destinations.contains(city);
                return ActionChip(
                  label: Text(city),
                  avatar: Icon(
                    isSelected ? Icons.check : Icons.add,
                    size: 16,
                    color: isSelected ? Colors.white : AppTheme.primaryGreen,
                  ),
                  backgroundColor: isSelected ? AppTheme.primaryGreen : Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  onPressed: () {
                    if (!isSelected) {
                      _addDestination(city);
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
        
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        
        // Datas
        const Text(
          'Período da viagem',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                label: 'Ida',
                date: _startDate,
                onTap: () => _selectDate(isStart: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePicker(
                label: 'Volta',
                date: _endDate,
                onTap: () => _selectDate(isStart: false),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Duração
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                '${_endDate.difference(_startDate).inDays + 1} dias de viagem',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${date.day} ${months[date.month - 1]} ${date.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Orçamento total (opcional)',
            hintText: 'Ex: 2000',
            prefixIcon: const Icon(Icons.attach_money),
            prefixText: 'R\$ ',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
          ),
          onChanged: (value) {
            _budget = double.tryParse(value.replaceAll(',', '.'));
          },
        ),
        
        const SizedBox(height: 24),
        
        // Resumo da viagem
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumo da Viagem',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(
                icon: Icons.luggage,
                label: 'Nome',
                value: _nameController.text.isEmpty ? 'Não definido' : _nameController.text,
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                icon: Icons.location_on,
                label: 'Destinos',
                value: _destinations.isEmpty ? 'Nenhum' : _destinations.join(' → '),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                icon: Icons.calendar_today,
                label: 'Período',
                value: '${_endDate.difference(_startDate).inDays + 1} dias',
              ),
              if (_budget != null) ...[
                const SizedBox(height: 12),
                _buildSummaryRow(
                  icon: Icons.attach_money,
                  label: 'Orçamento',
                  value: 'R\$ ${_budget!.toStringAsFixed(2)}',
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Após criar, você poderá adicionar paradas, restaurantes e atrações ao seu itinerário!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _addDestination(String destination) {
    final trimmed = destination.trim();
    if (trimmed.isNotEmpty && !_destinations.contains(trimmed)) {
      setState(() {
        _destinations.add(trimmed);
        _destinationController.clear();
      });
    }
  }

  void _removeDestination(int index) {
    setState(() {
      _destinations.removeAt(index);
    });
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime.now() : _startDate;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 3));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, dê um nome à viagem')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (_destinations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adicione pelo menos um destino')),
        );
        return;
      }
    }
    
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _createTrip();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _createTrip() async {
    debugPrint('🚀 _createTrip() chamada');
    
    // Não mais valida o form aqui - já validamos em cada step
    // if (!_formKey.currentState!.validate()) return;
    
    if (_isLoading) {
      debugPrint('⚠️ Já está carregando, ignorando');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      debugPrint('👤 userId: $userId');
      
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Criar dias para a viagem
      final days = <TripDay>[];
      var currentDate = _startDate;
      var dayNumber = 1;
      
      while (!currentDate.isAfter(_endDate)) {
        days.add(TripDay(
          id: 'day_${DateTime.now().millisecondsSinceEpoch}_$dayNumber',
          date: currentDate,
          title: 'Dia $dayNumber',
          stops: [],
        ));
        currentDate = currentDate.add(const Duration(days: 1));
        dayNumber++;
      }
      
      debugPrint('📅 ${days.length} dias criados');
      
      final trip = Trip(
        id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        status: TripStatus.planning,
        days: days,
        destinations: _destinations,
        totalBudget: _budget,
        createdAt: DateTime.now(),
      );
      
      debugPrint('📦 Trip criada: ${trip.name} (${trip.id})');
      debugPrint('📍 Destinos: ${trip.destinations}');
      
      await FirebaseService.saveTrip(trip);
      
      debugPrint('✅ Trip salva com sucesso no Firebase!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viagem criada com sucesso! 🎉'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.of(context).pop(true); // Retornar true para indicar sucesso
      }
    } catch (e) {
      debugPrint('❌ Erro ao criar viagem: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar viagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
