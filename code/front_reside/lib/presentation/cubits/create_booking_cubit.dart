import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/use_cases/create_booking_use_case.dart';
import 'create_booking_state.dart';

class CreateBookingCubit extends Cubit<CreateBookingState> {
  final CreateBookingUseCase _createBookingUseCase;

  CreateBookingCubit({required CreateBookingUseCase createBookingUseCase})
      : _createBookingUseCase = createBookingUseCase,
        super(CreateBookingInitial());

  Future<void> createBooking({
    required String amenityId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      emit(CreateBookingLoading());
      await _createBookingUseCase(
        amenityId: amenityId,
        startTime: startTime,
        endTime: endTime,
      );
      emit(CreateBookingSuccess());
    } catch (e) {
      emit(CreateBookingError(message: e.toString()));
    }
  }
}