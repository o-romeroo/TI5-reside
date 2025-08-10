import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/api_config.dart';
import '../models/booking_model.dart';

abstract class IBookingApiDataSource {
  Future<BookingModel> createBooking({
    required String amenityId,
    required String startTime,
    required String endTime,
  });

  Future<List<BookingModel>> fetchBookingsByDateRange(String start, String end);
}

class BookingApiDataSource implements IBookingApiDataSource {
  final http.Client client;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final _baseUrl = ApiConfig.baseUrl;

  BookingApiDataSource({required this.client});

  @override
  Future<BookingModel> createBooking({ required String amenityId, 
                                       required String startTime, 
                                       required String endTime,}) async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final body = {
      'amenityId': amenityId,
      'startTime': startTime,
      'endTime': endTime,
    };

    final response = await client.post(
      Uri.parse('$_baseUrl/bookings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      return BookingModel.fromJson(json.decode(response.body));
    } else if (response.statusCode == 409) {
      throw Exception('Booking conflict: Time slot not available.');
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['error'] ?? 'Failed to create booking.');
    }
  }

  Future<List<BookingModel>> fetchBookingsByDateRange(String start, String end) async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) throw Exception('Authentication token not found.');

    final uri = Uri.parse(
      '$_baseUrl/bookings',
    ).replace(queryParameters: {'startDate': start, 'endDate': end});

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => BookingModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load bookings. '
        'Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }
}
