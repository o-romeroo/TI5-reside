import '../../domain/entities/booking_entity.dart';
import '../models/booking_model.dart';

class BookingMapper {
  static BookingEntity toEntity(BookingModel model) {
    BookingStatus status;
    switch (model.status) {
      case 'confirmed':
        status = BookingStatus.confirmed;
        break;
      case 'pending':
        status = BookingStatus.pending;
        break;
      case 'cancelled':
        status = BookingStatus.cancelled;
        break;
      default:
        status = BookingStatus.unknown;
    }

    return BookingEntity(
      id: model.id,
      amenityId: model.amenityId,
      residentId: model.residentId,
      startTime: DateTime.parse(model.startTime),
      endTime: DateTime.parse(model.endTime),
      status: status,
      amenityName: model.amenityName ?? 'Área Desconhecida',
      residentName: model.residentName ?? 'Morador não identificado'
    );
  }
}