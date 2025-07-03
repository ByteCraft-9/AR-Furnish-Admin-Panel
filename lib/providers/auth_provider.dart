import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  UserModel? _userData;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  UserModel? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Constructor
  AuthProvider() {
    _init();
  }

  // Initialize provider
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // Listen to auth state changes
    _authService.authStateChanges.listen(_onAuthStateChanged);

    _isLoading = false;
    notifyListeners();
  }

  // Auth state change handler
  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;

    if (user != null) {
      // Get user data from firestore
      _userData = await _authService.getUserData();
    } else {
      _userData = null;
    }

    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmail(email, password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'An error occurred during sign in');
      _setLoading(false);
      return false;
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmail(
      String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signUpWithEmail(name, email, password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'An error occurred during sign up');
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _user = null;
      _userData = null;
      _setLoading(false);
    } catch (e) {
      _setError('Sign out failed: $e');
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'An error occurred during password reset');
      _setLoading(false);
      return false;
    }
  }

  // Update user data
  Future<bool> updateUserData(UserModel userData) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.updateUserData(userData);
      _userData = userData;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update user data: $e');
      _setLoading(false);
      return false;
    }
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
