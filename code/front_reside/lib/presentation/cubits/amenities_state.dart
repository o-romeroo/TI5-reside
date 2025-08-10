import 'package:equatable/equatable.dart';
import '../../domain/entities/amenity_entity.dart';

abstract class AmenitiesState extends Equatable {
  const AmenitiesState();

  @override
  List<Object> get props => [];
}

class AmenitiesInitial extends AmenitiesState {}

class AmenitiesLoading extends AmenitiesState {}

class AmenitiesLoaded extends AmenitiesState {
  final List<AmenityEntity> amenities;

  const AmenitiesLoaded({required this.amenities});

  @override
  List<Object> get props => [amenities];
}

class AmenitiesError extends AmenitiesState {
  final String message;

  const AmenitiesError({required this.message});

  @override
  List<Object> get props => [message];
}