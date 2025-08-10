enum BookingStatus { confirmed, pending, cancelled, unknown }

class BookingEntity {
  final String id;
  final String amenityId;
  final String residentId;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final String amenityName;
  final String residentName;

  BookingEntity({
    required this.id,
    required this.amenityId,
    required this.residentId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.amenityName,
    required this.residentName
  });
}