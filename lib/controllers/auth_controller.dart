import 'package:elephant_tracker_app/models/app_user.dart';
import 'package:elephant_tracker_app/services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<AppUser?> loginUser(String username, String password) {
    if (username.isEmpty || password.isEmpty) {
      return Future.value(null);
    }
    return _authService.login(username, password);
  }

  Future<String?> createDriverAccount(String email, String password) {
    return _authService.createDriver(email, password);
  }

  // New method to handle logout
  Future<void> logoutUser() {
    return _authService.logout();
  }
}