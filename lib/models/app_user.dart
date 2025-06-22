enum UserRole { admin, driver }

class AppUser {
  final String id;
  final String username;
  final UserRole role;

  AppUser({required this.id, required this.username, required this.role});
}
