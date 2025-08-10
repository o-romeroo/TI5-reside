import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_entity.dart';

abstract class CalendarBookingsState extends Equatable {
  const CalendarBookingsState();
  @override
  List<Object> get props => [];
}

class CalendarBookingsInitial extends CalendarBookingsState {}
class CalendarBookingsLoading extends CalendarBookingsState {}

class CalendarBookingsLoaded extends CalendarBookingsState {
  final Map<DateTime, List<BookingEntity>> bookingsByDay;
  final List<DateTime> weekDays;

  const CalendarBookingsLoaded({required this.bookingsByDay, required this.weekDays});

  @override
  List<Object> get props => [bookingsByDay, weekDays];
}

class CalendarBookingsError extends CalendarBookingsState {
  final String message;
  const CalendarBookingsError({required this.message});
  @override
  List<Object> get props => [message];
}