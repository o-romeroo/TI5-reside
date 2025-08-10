import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/use_cases/get_amenities_use_case.dart';
import 'amenities_state.dart';

class AmenitiesCubit extends Cubit<AmenitiesState> {
  final GetAmenitiesUseCase _getAmenitiesUseCase;

  AmenitiesCubit({required GetAmenitiesUseCase getAmenitiesUseCase})
      : _getAmenitiesUseCase = getAmenitiesUseCase,
        super(AmenitiesInitial());

  Future<void> fetchAmenities() async {
    try {
      emit(AmenitiesLoading());
      final amenities = await _getAmenitiesUseCase();
      emit(AmenitiesLoaded(amenities: amenities));
    } catch (e) {
      emit(AmenitiesError(message: e.toString()));
    }
  }
}