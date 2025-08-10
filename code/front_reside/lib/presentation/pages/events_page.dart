import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:front_reside/application/use_cases/get_bookings_for_week_use_case.dart';
import 'package:front_reside/domain/entities/booking_entity.dart';
import 'package:front_reside/infrastructure/data_sources/booking_api_data_source.dart';
import 'package:front_reside/infrastructure/repositories/booking_repository_impl.dart';
import 'package:front_reside/presentation/cubits/calendar_bookings_cubit.dart';
import 'package:front_reside/presentation/cubits/calendar_bookings_state.dart';
import 'package:front_reside/presentation/pages/amenities_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final client = http.Client();
        final dataSource = BookingApiDataSource(client: client);
        final repository = BookingRepositoryImpl(dataSource: dataSource);
        final useCase = GetBookingsForWeekUseCase(repository);
        return CalendarBookingsCubit(getBookingsUseCase: useCase)
          ..fetchBookingsForWeek(DateTime.now());
      },
      
      child: Builder(
        builder: (builderContext) {
          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final calendarCubit = builderContext.read<CalendarBookingsCubit>();

                final bool? shouldReload = await Navigator.push(
                  builderContext,
                  MaterialPageRoute(builder: (context) => const AmenitiesPage()),
                );

                if (shouldReload == true && mounted) {
                  calendarCubit.fetchBookingsForWeek(DateTime.now());
                }
              },
              child: const Icon(Icons.add),
              backgroundColor: Colors.blue,
            ),
            body: Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Agenda da Semana',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildWeekDaysRow(),
                const SizedBox(height: 8),
                BlocConsumer<CalendarBookingsCubit, CalendarBookingsState>(
                  listener: (context, state) {
                      if (state is CalendarBookingsError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: ${state.message}'), backgroundColor: Colors.red),
                        );
                      }
                  },
                  builder: (context, state) {
                    if (state is CalendarBookingsLoaded) {
                      return _buildCalendarDaysRow(state.weekDays, DateTime.now());
                    }
                    return _buildCalendarDaysRow(
                        List.generate(7, (index) => DateTime.now().add(Duration(days: index - (DateTime.now().weekday % 7)))),
                        DateTime.now());
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BlocBuilder<CalendarBookingsCubit, CalendarBookingsState>(
                    builder: (context, state) {
                      if (state is CalendarBookingsLoading || state is CalendarBookingsInitial) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is CalendarBookingsLoaded) {
                        return RefreshIndicator(
                          onRefresh: () => context.read<CalendarBookingsCubit>().fetchBookingsForWeek(DateTime.now()),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.weekDays.length,
                            itemBuilder: (context, index) {
                              final day = state.weekDays[index];
                              final bookingsForDay = state.bookingsByDay[day] ?? [];
                              return _DayScheduleCard(
                                day: day,
                                bookings: bookingsForDay,
                              );
                            },
                          ),
                        );
                      }
                      return const Center(child: Text('Nenhuma reserva para exibir.'));
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekDaysRow() {
    const weekDays = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((day) => Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))).toList(),
      ),
    );
  }

  Widget _buildCalendarDaysRow(List<DateTime> weekDays, DateTime today) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((day) {
          final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isToday ? Colors.blue : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? Colors.white : Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  final DateTime day;
  final List<BookingEntity> bookings;

  const _DayScheduleCard({required this.day, required this.bookings});

  String _formatDay(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hoje';
    }
    return DateFormat('EEEE', 'pt_BR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('dd MMMM', 'pt_BR').format(day),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDay(day),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (bookings.isNotEmpty)
              Column(
                children: bookings.map((booking) => _BookingItem(booking: booking)).toList(),
              )
            else
              const Text('Sem reservas para este dia', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _BookingItem extends StatelessWidget {
  final BookingEntity booking;

  const _BookingItem({required this.booking});

  @override
  Widget build(BuildContext context) {
    final startTime = DateFormat.Hm().format(booking.startTime);
    final endTime = DateFormat.Hm().format(booking.endTime);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            startTime,
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.amenityName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'por ${booking.residentName}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontStyle: FontStyle.italic),
                ),
                Text(
                  'Das $startTime às $endTime',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}