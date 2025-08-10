import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_reside/domain/services/resident_service.dart';
import 'package:front_reside/domain/services/condominium_service.dart';

class UserProfileController extends ChangeNotifier {
  String? firstName;
  String? lastName;
  String? photoUrl;
  String? condoName;
  String? userRole;
  String? apartment;
  String? userId;
  int? condominiumId;

  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    final userInfo = await ResidentService().getUserInfo(idToken!);
    print('userInfo retornado do backend: $userInfo');
    final condoInfo = await CondominiumService().getCondoInfo(
      idToken,
      userInfo['condominium_id'],
    );

    firstName = userInfo['first_name'];
    lastName = userInfo['last_name'];
    photoUrl = user?.photoURL;
    condoName = condoInfo['name'];
    userRole = userInfo['role'];
    apartment = userInfo['apartment'];
    print('apartment atribuído no controller: $apartment'); 
    userId = userInfo['id'].toString();
    condominiumId = int.tryParse(userInfo['condominium_id'].toString());

    if (userRole == 'admin') {
      userRole = 'Síndico';
    } else if (userRole == 'user') {
      userRole = 'Morador';
    }
    notifyListeners();
  }
}
