class ParkingSpotFind {
  final int id;
  final int residentId;
  final String apartment;
  final int condominiumId;
  final String location;
  final String type;
  final double price;
  final String description;
  final String status;
  final bool isCovered;
  final String? availableDate;
  final String? startTime;
  final String? endTime;
  final bool sunday;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final int? reserverId;
  final String? reservationExpiresAt;
  final String? createdAt;
  final String? updatedAt;

  ParkingSpotFind({
    required this.id,
    required this.residentId,
    required this.apartment,
    required this.condominiumId,
    required this.location,
    required this.type,
    required this.price,
    required this.description,
    required this.status,
    required this.isCovered,
    this.availableDate,
    this.startTime,
    this.endTime,
    required this.sunday,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    this.reserverId,
    this.reservationExpiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ParkingSpotFind.fromJson(Map<String, dynamic> json) => ParkingSpotFind(
        id: json['id'],
        residentId: json['resident_id'],
        apartment: json['apartment'],
        condominiumId: json['condominium_id'],
        location: json['location'],
        type: json['type'],
        price: json['price'] is String
           ? double.tryParse(json['price']) ?? 0.0
           : (json['price'] as num).toDouble(),
        description: json['description'] ?? '',
        status: json['status'] ?? '',
        isCovered: json['is_covered'],
        availableDate: json['available_date'],
        startTime: json['start_time'],
        endTime: json['end_time'],
        sunday: json['sunday'] ?? false,
        monday: json['monday'] ?? false,
        tuesday: json['tuesday'] ?? false,
        wednesday: json['wednesday'] ?? false,
        thursday: json['thursday'] ?? false,
        friday: json['friday'] ?? false,
        saturday: json['saturday'] ?? false,
        reserverId: json['reserver_id'],
        reservationExpiresAt: json['reservation_expires_at'],
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt'],
      );
}