class BookingModel {
  final String id;
  final String amenityId;
  final String residentId;
  final String startTime;
  final String endTime;
  final String status;
  final String? amenityName;
  final String? residentName;

  BookingModel({
    required this.id,
    required this.amenityId,
    required this.residentId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.amenityName,
    this.residentName
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'].toString(),
      amenityId: json['amenity_id'].toString(),
      residentId: json['resident_id'].toString(),
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: json['status'],
      amenityName: json['amenity_name'],
      residentName: json['resident_name']
    );
  }
}