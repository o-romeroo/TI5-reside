import 'package:equatable/equatable.dart';

abstract class CreateBookingState extends Equatable {
  const CreateBookingState();

  @override
  List<Object> get props => [];
}

class CreateBookingInitial extends CreateBookingState {}

class CreateBookingLoading extends CreateBookingState {}

class CreateBookingSuccess extends CreateBookingState {}

class CreateBookingError extends CreateBookingState {
  final String message;

  const CreateBookingError({required this.message});

  @override
  List<Object> get props => [message];
}