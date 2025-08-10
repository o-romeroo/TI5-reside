import 'package:flutter/material.dart';

class NewEventPage extends StatefulWidget {
  const NewEventPage({super.key});

  @override
  State<NewEventPage> createState() => _NewEventPageState();
}

class _NewEventPageState extends State<NewEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: 0);

  List<String> selectedGuests = [];
  String? _selectedEventType;

  final List<String> availableGuests = [
    'Filipi',
    'Romero',
    'Neimar',
    'Neto',
    'Lucas',
  ];

  final List<String> eventTypes = [
    'Reunião',
    'Festa',
    'Consulta',
    'Compromisso',
    'Lembrete'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cancelar'),
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: const Text(
              'Salvar',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Novo Evento',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título do Evento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Convidados
              _buildGuestSelection(),
              const SizedBox(height: 16),
              
              // Data e Hora
              _buildDateTimeSection(),
              const SizedBox(height: 16),
              
              // Localização
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Localização',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Tipo de Evento
              _buildEventTypeDropdown(),
              const SizedBox(height: 16),
              
              // Descrição
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Convidados',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableGuests.map((guest) {
            final isSelected = selectedGuests.contains(guest);
            return FilterChip(
              label: Text(guest),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedGuests.add(guest);
                  } else {
                    selectedGuests.remove(guest);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data e Hora',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Início'),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => _selectDate(context, isStartDate: true),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _selectTime(context, isStartTime: true),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _startTime.format(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Término'),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => _selectDate(context, isStartDate: false),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _selectTime(context, isStartTime: false),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _endTime.format(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Evento',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedEventType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          hint: const Text('Selecione o tipo'),
          items: eventTypes.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedEventType = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, selecione um tipo';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, {required bool isStartTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          if (_startTime.hour > _endTime.hour ||
              (_startTime.hour == _endTime.hour && _startTime.minute > _endTime.minute)) {
            _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: 0);
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      final newEvent = {
        'title': _titleController.text,
        'guests': selectedGuests,
        'startDate': _startDate,
        'startTime': _startTime,
        'endDate': _endDate,
        'endTime': _endTime,
        'location': _locationController.text,
        'type': _selectedEventType,
        'description': _descriptionController.text,
      };
      
      print('Evento criado: $newEvent'); 
      
      Navigator.pop(context, newEvent); 
    }
  }
}