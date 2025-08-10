import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../data_sources/booking_api_data_source.dart';
import '../mappers/booking_mapper.dart';

class BookingRepositoryImpl implements IBookingRepository {
  final IBookingApiDataSource dataSource;

  BookingRepositoryImpl({required this.dataSource});

  @override
  Future<BookingEntity> create({
    required String amenityId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final startTimeString = startTime.toIso8601String();
      final endTimeString = endTime.toIso8601String();

      final bookingModel = await dataSource.createBooking(
        amenityId: amenityId,
        startTime: startTimeString,
        endTime: endTimeString,
      );

      return BookingMapper.toEntity(bookingModel);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<BookingEntity>> findByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final startTimeString = start.toIso8601String();
      final endTimeString = end.toIso8601String();

      final bookingModels = await dataSource.fetchBookingsByDateRange(
        startTimeString,
        endTimeString,
      );

      return bookingModels
          .map((model) => BookingMapper.toEntity(model))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
