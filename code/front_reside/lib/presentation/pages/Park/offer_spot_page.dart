import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../infrastructure/models/parking_spot_model.dart';
import '../../../domain/services/parking_spot_service.dart';
import '../../controllers/user_profile_controller.dart';

class OfferSpotPage extends StatefulWidget {
  const OfferSpotPage({super.key});

  @override
  State<OfferSpotPage> createState() => _OfferSpotPageState();
}

enum RentType { daily, monthly }

class _OfferSpotPageState extends State<OfferSpotPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  RentType _selectedRentType = RentType.daily;
  DateTime? _selectedDailyDate;
  TimeOfDay? _selectedDailyStartTime;
  TimeOfDay? _selectedDailyEndTime;

  // NOVOS CAMPOS PARA MENSAL
  TimeOfDay? _selectedMonthlyStartTime;
  TimeOfDay? _selectedMonthlyEndTime;
  DateTime? _selectedMonthlyAvailableDate; // NOVO: data a partir de quando a vaga mensal estará disponível

  double _monthlyPrice = 300.0;
  List<bool> _selectedWeekdays = List.generate(7, (index) => false);
  final List<String> _weekdayNames = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  double _dailyPrice = 0.0; // Valor inicial da diária
  bool _isCovered = false;

  final ParkingSpotService _parkingSpotService = ParkingSpotService();

  @override
  void dispose() {
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDailyDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDailyDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDailyDate) {
      setState(() {
        _selectedDailyDate = picked;
      });
    }
  }

  Future<void> _selectMonthlyAvailableDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonthlyAvailableDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedMonthlyAvailableDate) {
      setState(() {
        _selectedMonthlyAvailableDate = picked;
      });
    }
  }

  Future<void> _selectDailyTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? (_selectedDailyStartTime ?? TimeOfDay.now()) : (_selectedDailyEndTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedDailyStartTime = picked;
        } else {
          _selectedDailyEndTime = picked;
        }
      });
    }
  }

  Future<void> _selectMonthlyTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? (_selectedMonthlyStartTime ?? TimeOfDay.now()) : (_selectedMonthlyEndTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedMonthlyStartTime = picked;
        } else {
          _selectedMonthlyEndTime = picked;
        }
      });
    }
  }

  // Validação sem relação entre horários de início e fim
  String? _validateDailyTimePeriod() {
    if (_selectedDailyDate == null) return 'Por favor, selecione a data.';
    if (_selectedDailyStartTime == null) return 'Por favor, selecione a hora de início.';
    if (_selectedDailyEndTime == null) return 'Por favor, selecione a hora de fim.';

    final now = DateTime.now();
    final selectedStartDateTime = DateTime(
        _selectedDailyDate!.year, _selectedDailyDate!.month, _selectedDailyDate!.day,
        _selectedDailyStartTime!.hour, _selectedDailyStartTime!.minute);

    if (selectedStartDateTime.isBefore(now)) {
      return 'A hora de início não pode ser no passado.';
    }
    return null;
  }

  String? _validateMonthlyTimePeriod() {
    if (!_selectedWeekdays.any((element) => element == true)) {
      return 'Por favor, selecione pelo menos um dia da semana.';
    }
    if (_selectedMonthlyAvailableDate == null) {
      return 'Selecione a data de início da disponibilidade.';
    }
    if (_selectedMonthlyStartTime == null) return 'Selecione o horário de início.';
    if (_selectedMonthlyEndTime == null) return 'Selecione o horário de fim.';
    return null;
  }

  String get _formattedDailyPrice {
    final formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatCurrency.format(_dailyPrice);
  }

  String get _formattedMonthlyPrice {
    final formatCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatCurrency.format(_monthlyPrice);
  }

  Future<void> _submitOffer() async {
    final userProfile = Provider.of<UserProfileController>(context, listen: false);
    // Verifique se os dados estão carregados
    if ((userProfile.userId == null || userProfile.userId!.isEmpty) ||
        (userProfile.apartment == null || userProfile.apartment!.isEmpty) ||
        (userProfile.condominiumId == null || userProfile.condominiumId == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dados do usuário não carregados. Faça login novamente ou aguarde o carregamento.')),
      );
      return;
    }

    String? timeValidationError;
    if (_selectedRentType == RentType.daily) {
      timeValidationError = _validateDailyTimePeriod();
      _selectedWeekdays = List.generate(7, (_) => true);
    } else {
      timeValidationError = _validateMonthlyTimePeriod();
    }

    if (_formKey.currentState!.validate() && timeValidationError == null) {
      final spot = ParkingSpot(
        residentId: int.tryParse(userProfile.userId ?? '') ?? 0,
        apartment: userProfile.apartment ?? '',
        condominiumId: userProfile.condominiumId ?? 0,
        location: _locationController.text,
        type: _selectedRentType == RentType.daily ? 'diario' : 'mensal',
        price: _selectedRentType == RentType.daily ? _dailyPrice : _monthlyPrice,
        description: _noteController.text,
        isCovered: _isCovered,
        availableDate: _selectedRentType == RentType.daily
            ? (_selectedDailyDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDailyDate!) : '')
            : (_selectedMonthlyAvailableDate != null ? DateFormat('yyyy-MM-dd').format(_selectedMonthlyAvailableDate!) : ''),
        startTime: _selectedRentType == RentType.daily
            ? (_selectedDailyStartTime != null ? _selectedDailyStartTime!.format(context) : '')
            : (_selectedMonthlyStartTime != null ? _selectedMonthlyStartTime!.format(context) : ''),
        endTime: _selectedRentType == RentType.daily
            ? (_selectedDailyEndTime != null ? _selectedDailyEndTime!.format(context) : '')
            : (_selectedMonthlyEndTime != null ? _selectedMonthlyEndTime!.format(context) : ''),
        domingo: _selectedWeekdays[0],
        segunda: _selectedWeekdays[1],
        terca: _selectedWeekdays[2],
        quarta: _selectedWeekdays[3],
        quinta: _selectedWeekdays[4],
        sexta: _selectedWeekdays[5],
        sabado: _selectedWeekdays[6],
      );

      print('JSON enviado: ${spot.toJson()}');

      final success = await _parkingSpotService.offerSpot(spot);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vaga disponibilizada com sucesso!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao disponibilizar vaga.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(timeValidationError ?? "Por favor, preencha todos os campos corretamente."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Disponibilizar Vaga',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Informe os detalhes da sua vaga para alugar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueGrey[600],
                ),
              ),
              Text(
                'Informamos que cada apartamento só pode ofertar duas vaga por vez.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueGrey[600],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Localização da vaga (Ex: Bloco A, Vaga 123)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe a localização da vaga.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _isCovered,
                    onChanged: (value) {
                      setState(() {
                        _isCovered = value ?? false;
                      });
                    },
                  ),
                  const Text('Vaga coberta?'),
                ],
              ),
              Center(
                child: SegmentedButton<RentType>(
                  segments: const <ButtonSegment<RentType>>[
                    ButtonSegment<RentType>(
                      value: RentType.daily,
                      label: Text('Diária'),
                      icon: Icon(Icons.calendar_today),
                    ),
                    ButtonSegment<RentType>(
                      value: RentType.monthly,
                      label: Text('Mensal'),
                      icon: Icon(Icons.calendar_month),
                    ),
                  ],
                  selected: <RentType>{_selectedRentType},
                  onSelectionChanged: (Set<RentType> newSelection) {
                    setState(() {
                      _selectedRentType = newSelection.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    selectedBackgroundColor: Colors.blue.shade700,
                    selectedForegroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade700, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _selectedRentType == RentType.daily
                  ? Column(
                      children: [
                        GestureDetector(
                          onTap: () => _selectDailyDate(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(
                                text: _selectedDailyDate == null ? '' : DateFormat('dd/MM/yyyy').format(_selectedDailyDate!),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Data disponível',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: const Icon(Icons.calendar_today),
                                suffixIcon: const Icon(Icons.arrow_drop_down),
                              ),
                              validator: (value) {
                                if (_selectedDailyDate == null) {
                                  return 'Por favor, selecione uma data.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectDailyTime(context, true),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    readOnly: true,
                                    controller: TextEditingController(
                                      text: _selectedDailyStartTime == null ? '' : _selectedDailyStartTime!.format(context),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Hora Início',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      prefixIcon: const Icon(Icons.access_time),
                                      suffixIcon: const Icon(Icons.arrow_drop_down),
                                    ),
                                    validator: (value) {
                                      if (_selectedDailyStartTime == null) {
                                        return 'Selecione a hora de início.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectDailyTime(context, false),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    readOnly: true,
                                    controller: TextEditingController(
                                      text: _selectedDailyEndTime == null ? '' : _selectedDailyEndTime!.format(context),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Hora Fim',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      prefixIcon: const Icon(Icons.access_time),
                                      suffixIcon: const Icon(Icons.arrow_drop_down),
                                    ),
                                    validator: (value) {
                                      if (_selectedDailyEndTime == null) {
                                        return 'Selecione a hora de fim.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_validateDailyTimePeriod() != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _validateDailyTimePeriod()!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valor da Diária: ${_formattedDailyPrice}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[700],
                              ),
                            ),
                            Slider(
                              value: _dailyPrice,
                              min: 0.0,
                              max: 200.0,
                              divisions: 40, 
                              label: _formattedDailyPrice,
                              onChanged: (double value) {
                                setState(() {
                                  _dailyPrice = (value / 10).round() * 10.0;
                                });
                              },
                              activeColor: Colors.blue.shade700,
                              inactiveColor: Colors.blue.shade100,
                            ),
                            Text(
                              'Sugestão: Defina um preço justo para atrair mais interessados.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Dias da Semana Disponíveis:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: List.generate(7, (index) {
                            return ChoiceChip(
                              label: Text(_weekdayNames[index]),
                              selected: _selectedWeekdays[index],
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedWeekdays[index] = selected;
                                });
                              },
                              selectedColor: Colors.blue.shade100,
                              labelStyle: TextStyle(
                                color: _selectedWeekdays[index] ? Colors.blue.shade800 : Colors.black54,
                                fontWeight: _selectedWeekdays[index] ? FontWeight.bold : FontWeight.normal,
                              ),
                              side: BorderSide(color: Colors.blue.shade400, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => _selectMonthlyAvailableDate(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(
                                text: _selectedMonthlyAvailableDate == null
                                    ? ''
                                    : DateFormat('dd/MM/yyyy').format(_selectedMonthlyAvailableDate!),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Disponível a partir de',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: const Icon(Icons.calendar_today),
                                suffixIcon: const Icon(Icons.arrow_drop_down),
                              ),
                              validator: (value) {
                                if (_selectedMonthlyAvailableDate == null) {
                                  return 'Selecione a data de início da disponibilidade.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectMonthlyTime(context, true),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    readOnly: true,
                                    controller: TextEditingController(
                                      text: _selectedMonthlyStartTime == null ? '' : _selectedMonthlyStartTime!.format(context),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Hora Início',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      prefixIcon: const Icon(Icons.access_time),
                                      suffixIcon: const Icon(Icons.arrow_drop_down),
                                    ),
                                    validator: (value) {
                                      if (_selectedMonthlyStartTime == null) {
                                        return 'Selecione o horário de início.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectMonthlyTime(context, false),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    readOnly: true,
                                    controller: TextEditingController(
                                      text: _selectedMonthlyEndTime == null ? '' : _selectedMonthlyEndTime!.format(context),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Hora Fim',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      prefixIcon: const Icon(Icons.access_time),
                                      suffixIcon: const Icon(Icons.arrow_drop_down),
                                    ),
                                    validator: (value) {
                                      if (_selectedMonthlyEndTime == null) {
                                        return 'Selecione o horário de fim.';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_validateMonthlyTimePeriod() != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _validateMonthlyTimePeriod()!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valor Mensal: ${_formattedMonthlyPrice}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[700],
                              ),
                            ),
                            Slider(
                              value: _monthlyPrice,
                              min: 100.0,
                              max: 1000.0,
                              divisions: 180,
                              label: _formattedMonthlyPrice,
                              onChanged: (double value) {
                                setState(() {
                                  _monthlyPrice = value;
                                });
                              },
                              activeColor: Colors.blue.shade700,
                              inactiveColor: Colors.blue.shade100,
                            ),
                            Text(
                              'Sugestão: Valores mensais são mais vantajosos para ambos os lados.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Observações (Ex: vaga coberta, fácil acesso)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedRentType == RentType.daily ? Colors.blue.shade700 : Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  _selectedRentType == RentType.daily
                      ? "Disponibilizar Diária por ${_formattedDailyPrice}"
                      : "Disponibilizar Mensal por ${_formattedMonthlyPrice}",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}