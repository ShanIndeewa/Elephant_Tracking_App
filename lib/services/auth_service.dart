import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:elephant_tracker_app/models/app_user.dart' as model_user;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Fetches the user's role from the 'users' node in Realtime DB
  Future<model_user.UserRole> _getUserRole(String uid) async {
    try {
      final snapshot = await _db.ref('users/$uid/role').get();
      if (snapshot.exists && snapshot.value == 'admin') {
        return model_user.UserRole.admin;
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
    return model_user.UserRole.driver; // Default to driver
  }

  // Logs in a user via Firebase Auth
  Future<model_user.AppUser?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        final role = await _getUserRole(user.uid);
        return model_user.AppUser(
          id: user.uid,
          username: user.email ?? 'Unknown',
          role: role,
        );
      }
      return null;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // Creates a new user and adds their details to the Realtime Database
  Future<String?> createDriver(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        // Set the user's role in the database
        await _db.ref('users/${user.uid}').set({
          'email': email,
          'role': 'driver',
        });
        return null; // Success
      }
      return "Failed to get user after creation.";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }
}