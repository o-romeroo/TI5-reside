class ParkingSpot {
  final int residentId;
  final String apartment;
  final int condominiumId;
  final String location;
  final String type; // 'diario' ou 'mensal'
  final double price;
  final String description;
  final bool isCovered;
  final String availableDate; // formato: 'YYYY-MM-DD'
  final String startTime;     // formato: 'HH:mm'
  final String endTime;       // formato: 'HH:mm'
  final bool domingo;
  final bool segunda;
  final bool terca;
  final bool quarta;
  final bool quinta;
  final bool sexta;
  final bool sabado;

  ParkingSpot({
    required this.residentId,
    required this.apartment,
    required this.condominiumId,
    required this.location,
    required this.type,
    required this.price,
    required this.description,
    required this.isCovered,
    required this.availableDate,
    required this.startTime,
    required this.endTime,
    required this.domingo,
    required this.segunda,
    required this.terca,
    required this.quarta,
    required this.quinta,
    required this.sexta,
    required this.sabado,
  });

  Map<String, dynamic> toJson() => {
        'resident_id': residentId,
        'apartment': apartment,
        'condominium_id': condominiumId,
        'location': location,
        'type': type,
        'price': price,
        'description': description,
        'is_covered': isCovered,
        'available_date': availableDate,
        'start_time': startTime,
        'end_time': endTime,
        'domingo': domingo,
        'segunda': segunda,
        'terca': terca,
        'quarta': quarta,
        'quinta': quinta,
        'sexta': sexta,
        'sabado': sabado,
      };
}