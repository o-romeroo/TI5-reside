import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/use_cases/get_bookings_for_week_use_case.dart';
import '../../domain/entities/booking_entity.dart';
import 'calendar_bookings_state.dart';

DateTime _truncateToDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

class CalendarBookingsCubit extends Cubit<CalendarBookingsState> {
  final GetBookingsForWeekUseCase _getBookingUseCase;

  CalendarBookingsCubit({required GetBookingsForWeekUseCase getBookingsUseCase})
      : _getBookingUseCase = getBookingsUseCase,
        super(CalendarBookingsInitial());

  Future<void> fetchBookingsForWeek(DateTime dateInWeek) async {
    try {
      emit(CalendarBookingsLoading());
      
      final bookings = await _getBookingUseCase(dateInWeek);
      final bookingsByDay = _groupBookingsByDay(bookings);
      final weekDays = _getWeekDays(dateInWeek);

      emit(CalendarBookingsLoaded(bookingsByDay: bookingsByDay, weekDays: weekDays));
    } catch (e) {
      emit(CalendarBookingsError(message: e.toString()));
    }
  }

  Map<DateTime, List<BookingEntity>> _groupBookingsByDay(List<BookingEntity> bookings) {
    final map = <DateTime, List<BookingEntity>>{};
    for (final booking in bookings) {
      final dayKey = _truncateToDay(booking.startTime);
      
      if (map[dayKey] == null) {
        map[dayKey] = [];
      }
      map[dayKey]!.add(booking);
    }

    map.forEach((key, value) {
      value.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
    return map;
  }

  List<DateTime> _getWeekDays(DateTime dateInWeek) {
    final startOfWeek = _truncateToDay(dateInWeek.subtract(Duration(days: dateInWeek.weekday % 7)));

    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }
}