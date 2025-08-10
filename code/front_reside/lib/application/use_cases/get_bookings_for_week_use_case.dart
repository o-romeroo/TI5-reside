import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';

class GetBookingsForWeekUseCase {
  final IBookingRepository _bookingRepository;

  GetBookingsForWeekUseCase(this._bookingRepository);

  Future<List<BookingEntity>> call(DateTime dateInWeek) async {
    final dayOfWeek = dateInWeek.weekday;
    final startOfWeek = dateInWeek.subtract(Duration(days: dayOfWeek % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));

    return await _bookingRepository.findByDateRange(startOfWeek, endOfWeek);
  }
}