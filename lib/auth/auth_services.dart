import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      log("User created with email: $email");
      return cred.user;
    } catch (e) {
      log("Error during signup: $e");
      return null;
    }
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      log("User logged in with email: $email");
      return cred.user;
    } catch (e) {
      log("Error during login: $e");
      return null;
    }
  }

  Future<void> signout() async {
    try {
      await _auth.signOut();
      log("User signed out");
    } catch (e) {
      log("Error during signout: $e");
    }
  }
}
