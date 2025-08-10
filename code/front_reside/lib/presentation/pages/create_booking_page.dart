import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../application/use_cases/create_booking_use_case.dart';
import '../../infrastructure/data_sources/booking_api_data_source.dart';
import '../../infrastructure/repositories/booking_repository_impl.dart';
import '../cubits/create_booking_cubit.dart';
import '../cubits/create_booking_state.dart';

class CreateBookingPage extends StatefulWidget {
  final String amenityId;
  final String amenityName;

  const CreateBookingPage({
    super.key,
    required this.amenityId,
    required this.amenityName,
  });

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final _formKey = GlobalKey<FormState>();

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _submitBooking(BuildContext cubitContext) {
    if (_startTime == null || _endTime == null) {
      _showErrorSnackBar('Por favor, selecione o horário de início e término.');
      return;
    }

    final startDateTime = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _startTime!.hour, _startTime!.minute);
    final endDateTime = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _endTime!.hour, _endTime!.minute);
        
    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
        _showErrorSnackBar('O horário de término deve ser após o horário de início.');
        return;
    }

    final now = DateTime.now();
    if (startDateTime.isBefore(now)) {
      _showErrorSnackBar('Não é possível agendar uma reserva no passado.');
      return;
    }

    const int minHour = 10;
    const int maxHour = 22;

    if (startDateTime.hour < minHour || startDateTime.hour >= maxHour) {
      _showErrorSnackBar('O horário de início deve ser entre 10:00 e 21:00.');
      return;
    }

    if (endDateTime.hour > maxHour || (endDateTime.hour == maxHour && endDateTime.minute > 0)) {
       _showErrorSnackBar('O horário de término deve ser até as 22:00.');
       return;
    }

    cubitContext.read<CreateBookingCubit>().createBooking(
          amenityId: widget.amenityId,
          startTime: startDateTime,
          endTime: endDateTime,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final client = http.Client();
        final dataSource = BookingApiDataSource(client: client);
        final repository = BookingRepositoryImpl(dataSource: dataSource);
        final useCase = CreateBookingUseCase(repository);
        return CreateBookingCubit(createBookingUseCase: useCase);
      },
      child: Builder(
        builder: (builderContext) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Reservar ${widget.amenityName}'),
            ),
            body: BlocListener<CreateBookingCubit, CreateBookingState>(
              listener: (context, state) {
                if (state is CreateBookingSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reserva realizada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop(true);
                } else if (state is CreateBookingError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro da API: ${state.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDatePicker(builderContext),
                      const SizedBox(height: 24),
                      _buildTimePickers(builderContext),
                      const SizedBox(height: 32),
                      _buildConfirmButton(builderContext),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. Selecione o dia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
          onTap: () => _pickDate(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildTimePickers(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('2. Selecione o horário', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _timePickerField(context, 'Início', _startTime, true)),
            const SizedBox(width: 16),
            Expanded(child: _timePickerField(context, 'Término', _endTime, false)),
          ],
        ),
      ],
    );
  }

  Widget _timePickerField(BuildContext context, String label, TimeOfDay? time, bool isStart) {
    return InkWell(
      onTap: () => _pickTime(context, isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(time?.format(context) ?? 'HH:MM'),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime ?? TimeOfDay.now() : _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Widget _buildConfirmButton(BuildContext context) {
    return BlocBuilder<CreateBookingCubit, CreateBookingState>(
      builder: (cubitContext, state) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: state is CreateBookingLoading ? null : () => _submitBooking(context),
            child: state is CreateBookingLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Confirmar Reserva'),
          ),
        );
      },
    );
  }
}