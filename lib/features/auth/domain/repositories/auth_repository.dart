import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> getCurrentUser();
}
