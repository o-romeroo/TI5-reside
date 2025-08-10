import 'package:flutter/material.dart';
import 'package:front_reside/presentation/controllers/parking_spot_find_controller.dart';
import 'package:intl/intl.dart';
import '../../../infrastructure/models/parking_spot_find_model.dart';
import '../../../domain/services/parking_spot_find_service.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_profile_controller.dart';

class FindSpotPage extends StatefulWidget {
  const FindSpotPage({super.key});

  @override
  State<FindSpotPage> createState() => _FindSpotPageState();
}

enum RentType { daily, monthly }

class _FindSpotPageState extends State<FindSpotPage> {
  final TextEditingController _locationSearchController =
      TextEditingController();
  final TextEditingController _maxPriceFilterController =
      TextEditingController();

  RentType _selectedRentType = RentType.daily;

  DateTime? _selectedDateFilter;
  TimeOfDay? _selectedStartTimeFilter;
  TimeOfDay? _selectedEndTimeFilter;

  List<bool> _selectedWeekdayFilter = List.generate(7, (index) => false);
  final List<String> _weekdayNames = [
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
  ];
  final List<String> _weekdayLabels = [
    'Dom',
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
  ];

  List<ParkingSpotFind> _availableSpots = [];
  bool _loading = false;
  String? _error;

  final ParkingSpotFindService _service = ParkingSpotFindService();

  @override
  void initState() {
    super.initState();
    _fetchSpots();
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    _maxPriceFilterController.dispose();
    super.dispose();
  }

  Future<void> _fetchSpots() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // final filters = <String, dynamic>{};
      // filters['condominium_id'] = '1'; // pegar o usuario para poder pegar o id do condominio deleeeeeeeeeeeeeeeeeeeeeeeeeee
      final userProfile = Provider.of<UserProfileController>(
        context,
        listen: false,
      );
      final filters = <String, dynamic>{};
      filters['condominium_id'] = userProfile.condominiumId?.toString() ?? '';
      if (_locationSearchController.text.isNotEmpty) {
        filters['location'] = _locationSearchController.text;
      }
      if (_maxPriceFilterController.text.isNotEmpty) {
        filters['max_price'] = _maxPriceFilterController.text;
      }
      if (_selectedRentType == RentType.daily) {
        filters['type'] = 'diario';
        if (_selectedDateFilter != null) {
          filters['date'] = DateFormat(
            'yyyy-MM-dd',
          ).format(_selectedDateFilter!);
        }
        if (_selectedStartTimeFilter != null) {
          filters['start_time'] = _selectedStartTimeFilter!.format(context);
        }
        if (_selectedEndTimeFilter != null) {
          filters['end_time'] = _selectedEndTimeFilter!.format(context);
        }
      } else {
        filters['type'] = 'mensal';
        // Envia os dias da semana como booleans separados (ex: monday=true)
        for (int i = 0; i < 7; i++) {
          if (_selectedWeekdayFilter[i]) {
            filters[_weekdayNames[i]] = 'true';
          }
        }
      }
      final spots = await _service.getAvailable(filters: filters);
      setState(() {
        _availableSpots = spots;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _selectDateFilter(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      helpText: 'Selecione a Data',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateFilter) {
      setState(() {
        _selectedDateFilter = picked;
      });
      _fetchSpots();
    }
  }

  Future<void> _selectTimeFilter(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          isStartTime
              ? (_selectedStartTimeFilter ?? TimeOfDay.now())
              : (_selectedEndTimeFilter ?? TimeOfDay.now()),
      helpText: isStartTime ? 'Hora de Início' : 'Hora de Fim',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTimeFilter = picked;
        } else {
          _selectedEndTimeFilter = picked;
        }
      });
      _fetchSpots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Procurar Vaga',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _locationSearchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar por localização (Ex: Bloco A)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _locationSearchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _locationSearchController.clear();
                                _fetchSpots();
                              },
                            )
                            : null,
                  ),
                  onChanged: (_) => _fetchSpots(),
                ),
                const SizedBox(height: 16),
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
                        _selectedDateFilter = null;
                        _selectedStartTimeFilter = null;
                        _selectedEndTimeFilter = null;
                        _selectedWeekdayFilter = List.generate(
                          7,
                          (index) => false,
                        );
                      });
                      _fetchSpots();
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor:
                          _selectedRentType == RentType.daily
                              ? Colors.blue.shade50
                              : Colors.blue.shade50,
                      selectedBackgroundColor:
                          _selectedRentType == RentType.daily
                              ? Colors.blue.shade700
                              : Colors.blue.shade700,
                      selectedForegroundColor: Colors.white,
                      foregroundColor:
                          _selectedRentType == RentType.daily
                              ? Colors.blue.shade700
                              : Colors.blue.shade700,
                      side: BorderSide(
                        color:
                            _selectedRentType == RentType.daily
                                ? Colors.blue.shade700
                                : Colors.blue.shade700,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _selectedRentType == RentType.daily
                    ? Column(
                      children: [
                        GestureDetector(
                          onTap: () => _selectDateFilter(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(
                                text:
                                    _selectedDateFilter == null
                                        ? ''
                                        : DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_selectedDateFilter!),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Filtrar por Data',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.calendar_month),
                                suffixIcon:
                                    _selectedDateFilter != null
                                        ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _selectedDateFilter = null;
                                            });
                                            _fetchSpots();
                                          },
                                        )
                                        : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTimeFilter(context, true),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    readOnly: true,
                                    controller: TextEditingController(
                                      text:
                                          _selectedStartTimeFilter == null
                                              ? ''
                                              : _selectedStartTimeFilter!
                                                  .format(context),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Hora Início',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: const Icon(Icons.access_time),
                                      suffixIcon:
                                          _selectedStartTimeFilter != null
                                              ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedStartTimeFilter =
                                                        null;
                                                  });
                                                  _fetchSpots();
                                                },
                                              )
                                              : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTimeFilter(context, false),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    readOnly: true,
                                    controller: TextEditingController(
                                      text:
                                          _selectedEndTimeFilter == null
                                              ? ''
                                              : _selectedEndTimeFilter!.format(
                                                context,
                                              ),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Hora Fim',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: const Icon(Icons.access_time),
                                      suffixIcon:
                                          _selectedEndTimeFilter != null
                                              ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedEndTimeFilter =
                                                        null;
                                                  });
                                                  _fetchSpots();
                                                },
                                              )
                                              : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrar por Dias da Semana:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: List.generate(7, (index) {
                            return ChoiceChip(
                              label: Text(_weekdayLabels[index]),
                              selected: _selectedWeekdayFilter[index],
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedWeekdayFilter[index] = selected;
                                });
                                _fetchSpots();
                              },
                              selectedColor: Colors.blue.shade100,
                              labelStyle: TextStyle(
                                color:
                                    _selectedWeekdayFilter[index]
                                        ? Colors.blue.shade800
                                        : Colors.black54,
                                fontWeight:
                                    _selectedWeekdayFilter[index]
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: Colors.blue.shade400,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxPriceFilterController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        _selectedRentType == RentType.daily
                            ? 'Valor Máximo por Hora (R\$)'
                            : 'Valor Máximo Mensal (R\$)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixIcon:
                        _maxPriceFilterController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _maxPriceFilterController.clear();
                                _fetchSpots();
                              },
                            )
                            : null,
                  ),
                  onChanged: (_) => _fetchSpots(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                    : _availableSpots.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sentiment_dissatisfied,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma vaga encontrada com esses filtros.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _availableSpots.length,
                      itemBuilder: (context, index) {
                        final vaga = _availableSpots[index];
                        return SpotCard(
                          spot: vaga,
                          onRequestSuccess: _fetchSpots,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class SpotCard extends StatelessWidget {
  final ParkingSpotFind spot;
  final VoidCallback onRequestSuccess;

  const SpotCard({
    super.key,
    required this.spot,
    required this.onRequestSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final String priceText =
        spot.type == 'diario'
            ? '${formatCurrency.format(spot.price)}/dia'
            : '${formatCurrency.format(spot.price)}/mês';

    final userProfile = Provider.of<UserProfileController>(
      context,
      listen: false,
    );
    final int residentId = int.tryParse(userProfile.userId ?? '') ?? 0;
    final bool isOwnSpot = spot.residentId == residentId;

    String timeInfo;
    if (spot.type == 'diario') {
      timeInfo =
          'Disponível: ${spot.availableDate != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(spot.availableDate!)) : ''}'
          ' das ${spot.startTime ?? ''} às ${spot.endTime ?? ''}';
    } else {
      final List<String> selectedDays = [];
      final List<String> weekdayNames = [
        'Dom',
        'Seg',
        'Ter',
        'Qua',
        'Qui',
        'Sex',
        'Sáb',
      ];
      final days = [
        spot.sunday,
        spot.monday,
        spot.tuesday,
        spot.wednesday,
        spot.thursday,
        spot.friday,
        spot.saturday,
      ];
      for (int i = 0; i < 7; i++) {
        if (days[i]) selectedDays.add(weekdayNames[i]);
      }
      timeInfo = 'Disponível a partir: ${selectedDays.join(', ')}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.local_parking, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              spot.location,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeInfo,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              spot.description,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  priceText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color:
                        spot.type == 'diario'
                            ? Colors.blue.shade700
                            : Colors.blue.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      isOwnSpot
                          ? null
                          : () async {
                            try {
                              await ParkingSpotFindController().rentSpot(
                                spot.id,
                                residentId,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Vaga alugada com sucesso!",
                                  ),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                              onRequestSuccess();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Erro ao solicitar vaga: $e"),
                                ),
                              );
                            }
                          },
                  icon: const Icon(Icons.send_outlined, size: 20),
                  label: Text(isOwnSpot ? "Sua vaga" : "Solicitar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isOwnSpot
                            ? Colors.grey
                            : (spot.type == 'diario'
                                ? Colors.blue
                                : Colors.blue),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            if (isOwnSpot)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Você não pode solicitar sua própria vaga.",
                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
