import '../entities/heart_status.dart';

abstract class HeartRepository {
  Future<HeartStatus> getMyHearts();

  Future<HeartStatus> refillHearts();
}
