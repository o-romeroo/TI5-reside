import 'package:front_reside/domain/entities/resident_entity.dart';

abstract class IResidentRepository {
  Future<ResidentEntity> getResidentData(String residentId);
}
