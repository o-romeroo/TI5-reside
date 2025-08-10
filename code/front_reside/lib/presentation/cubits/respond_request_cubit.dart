import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../application/use_cases/respond_to_request_use_case.dart';

// Estados
abstract class RespondRequestState extends Equatable {
  @override
  List<Object> get props => [];
}
class RespondRequestInitial extends RespondRequestState {}
class RespondRequestLoading extends RespondRequestState {}
class RespondRequestSuccess extends RespondRequestState {}
class RespondRequestError extends RespondRequestState {
  final String message;
  RespondRequestError(this.message);
  @override
  List<Object> get props => [message];
}

// Cubit
class RespondRequestCubit extends Cubit<RespondRequestState> {
  final RespondToRequestUseCase _respondUseCase;

  RespondRequestCubit(this._respondUseCase) : super(RespondRequestInitial());

  Future<void> respond({required String id, required String response}) async {
    try {
      emit(RespondRequestLoading());
      await _respondUseCase(id: id, response: response);
      emit(RespondRequestSuccess());
    } catch (e) {
      emit(RespondRequestError(e.toString()));
    }
  }
}