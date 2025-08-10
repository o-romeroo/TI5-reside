import '../entities/booking_entity.dart';

abstract class IBookingRepository {
  Future<BookingEntity> create(
      {required String amenityId,
      required DateTime startTime,
      required DateTime endTime});

  Future<List<BookingEntity>> findByDateRange(DateTime start, DateTime end);
}