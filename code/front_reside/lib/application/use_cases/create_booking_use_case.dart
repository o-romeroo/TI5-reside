import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';

class CreateBookingUseCase {
  final IBookingRepository _bookingRepository;

  CreateBookingUseCase(this._bookingRepository);

  Future<BookingEntity> call(
      {required String amenityId,
      required DateTime startTime,
      required DateTime endTime}) async {

    if (endTime.isBefore(startTime)) {
      throw ArgumentError('End time cannot be before start time.');
    }

    return await _bookingRepository.create(
      amenityId: amenityId,
      startTime: startTime,
      endTime: endTime,
    );
  }
}