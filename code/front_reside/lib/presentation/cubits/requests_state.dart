import 'package:equatable/equatable.dart';
import '../../domain/entities/request_entity.dart';

abstract class RequestsState extends Equatable {
  const RequestsState();
  @override
  List<Object> get props => [];
}

class RequestsInitial extends RequestsState {}
class RequestsLoading extends RequestsState {}

class RequestsLoaded extends RequestsState {
  final List<RequestEntity> openRequests;
  final List<RequestEntity> closedRequests;

  const RequestsLoaded({required this.openRequests, required this.closedRequests});

  @override
  List<Object> get props => [openRequests, closedRequests];
}

class RequestsError extends RequestsState {
  final String message;
  const RequestsError({required this.message});
  @override
  List<Object> get props => [message];
}