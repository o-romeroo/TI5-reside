import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/use_cases/get_requests_use_case.dart';
import '../../domain/entities/request_entity.dart';
import 'requests_state.dart';

class RequestsCubit extends Cubit<RequestsState> {
  final GetRequestsUseCase _getRequestsUseCase;

  RequestsCubit(this._getRequestsUseCase) : super(RequestsInitial());

  Future<void> fetchRequests() async {
    try {
      emit(RequestsLoading());
      final allRequests = await _getRequestsUseCase(); 
      final open = allRequests.where((r) => r.status == RequestStatus.open).toList();
      final closed = allRequests.where((r) => r.status == RequestStatus.closed).toList();
      emit(RequestsLoaded(openRequests: open, closedRequests: closed));
    } catch (e) {
      emit(RequestsError(message: e.toString()));
    }
  }
}