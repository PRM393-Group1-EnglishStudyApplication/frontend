import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository _repository;

  const GetCurrentUser(this._repository);

  Future<AppUser> call() {
    return _repository.getCurrentUser();
  }
}
