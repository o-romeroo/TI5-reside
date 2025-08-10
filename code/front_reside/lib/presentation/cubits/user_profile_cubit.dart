import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/services/resident_service.dart';

abstract class UserProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}
class UserProfileInitial extends UserProfileState {}
class UserProfileLoading extends UserProfileState {}
class UserProfileLoaded extends UserProfileState {
  final String firstName;
  final String lastName;
  final String userRole;
  final String? photoUrl;
  final String? condoName;
  final String? apartment;

  UserProfileLoaded({
    required this.firstName,
    required this.lastName,
    required this.userRole,
    this.photoUrl,
    this.condoName,
    this.apartment,
  });

  @override
  List<Object?> get props => [firstName, lastName, userRole, photoUrl, condoName, apartment];
}
class UserProfileError extends UserProfileState {
  final String message;
  UserProfileError(this.message);
  @override
  List<Object> get props => [message];
}

class UserProfileCubit extends Cubit<UserProfileState> {
  final ResidentService _residentService = ResidentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserProfileCubit() : super(UserProfileInitial());

  Future<void> loadUserProfile() async {
    try {
      emit(UserProfileLoading());
      final user = _auth.currentUser;
      if (user == null) {
        emit(UserProfileError("User not authenticated."));
        return;
      }
      
      final idToken = await user.getIdToken();
      if (idToken == null) {
        emit(UserProfileError("Could not retrieve auth token."));
        return;
      }

      final data = await _residentService.getUserInfo(idToken);
      emit(UserProfileLoaded(
        firstName: data['first_name'] ?? '',
        lastName: data['last_name'] ?? '',
        userRole: data['role'] ?? 'user',
        photoUrl: user.photoURL,
        condoName: data['condominium_name'],
        apartment: data['apartment'],
      ));
    } catch (e) {
      emit(UserProfileError(e.toString()));
    }
  }
}