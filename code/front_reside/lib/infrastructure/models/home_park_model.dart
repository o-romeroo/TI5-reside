class HomePark {
  final int id;
  final int residentId; 
  final String apartment; 
  final int condominiumId;
  final String location;
  final String type;
  final String price;
  final String description;
  final String status;
  final bool isCovered;
  final String? availableDate;
  final String? startTime;
  final String? endTime;
  final int? reserverId; 
  final String? reservationExpiresAt;  
  final String? reserverName;  
  final ReserverDetails? reserverDetails; 
  final String? ownerName;     
  final OwnerDetails? ownerDetails; 

  HomePark({
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
    this.reserverId,
    this.reservationExpiresAt,
    this.reserverName,
    this.reserverDetails,
    this.ownerName,
    this.ownerDetails,
  });

  factory HomePark.fromJson(Map<String, dynamic> json) {
    return HomePark(
      id: json['id'],
      residentId: json['resident_id'],
      apartment: json['apartment'],
      condominiumId: json['condominium_id'],
      location: json['location'],
      type: json['type'],
      price: json['price'].toString(),
      description: json['description'] ?? '',
      status: json['status'],
      isCovered: json['is_covered'],
      availableDate: json['available_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      reserverId: json['reserver_id'],
      reservationExpiresAt: json['reservation_expires_at'],
      
      reserverName: json['reserver_name'],
      reserverDetails: json['reserver_details'] != null 
          ? ReserverDetails.fromJson(json['reserver_details']) 
          : null,
      
      ownerName: json['owner_name'],
      ownerDetails: json['owner_details'] != null 
          ? OwnerDetails.fromJson(json['owner_details']) 
          : null,
    );
  }
}

class ReserverDetails {
  final String id;
  final String? apartment;
  final String? contactPhone;


  ReserverDetails({
    required this.id,
    this.apartment,
    this.contactPhone,
  });

  factory ReserverDetails.fromJson(Map<String, dynamic> json) {
    return ReserverDetails(
      id: json['id'].toString(),
      apartment: json['apartment'],
      contactPhone: json['contact_phone'],
    );
  }
}

class OwnerDetails {
  final String id;
  final String? apartment;
  final String? contactPhone;

  OwnerDetails({
    required this.id,
    this.apartment,
    this.contactPhone,
  });

  factory OwnerDetails.fromJson(Map<String, dynamic> json) {
    return OwnerDetails(
      id: json['id'].toString(),
      apartment: json['apartment'],
      contactPhone: json['contact_phone'],
    );
  }
}
