// lib/services/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isAdmin => _profile?.isAdmin ?? false;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    UserRole role = UserRole.general,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _authService.register(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
      role: role,
    );

    if (!result.success) _errorMessage = result.message;
    _setLoading(false);
    return result;
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _authService.login(email: email, password: password);

    if (result.success) {
      await loadProfile();
    } else {
      _errorMessage = result.message;
    }

    _setLoading(false);
    return result;
  }

  Future<void> loadProfile() async {
    _profile = await _authService.fetchProfile();
    notifyListeners();
  }

  Future<List<UserProfile>> fetchAllUsers() async {
    return _authService.fetchAllUsers();
  }

  Future<AuthResult> updateUserRole(String userId, UserRole role) async {
    _setLoading(true);
    final result = await _authService.updateUserRole(userId, role);
    _setLoading(false);
    return result;
  }

  Future<AuthResult> updateProfile({
    required String fullName,
    String? phone,
    String? bio,
  }) async {
    if (_profile == null) return AuthResult.error('Not logged in.');
    _setLoading(true);
    final result = await _authService.updateProfile(
      userId: _profile!.id,
      fullName: fullName,
      phone: phone,
      bio: bio,
    );
    if (result.success) await loadProfile();
    _setLoading(false);
    return result;
  }

  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _profile = null;
    _setLoading(false);
  }

  Future<AuthResult> resetPassword(String email) async {
    _setLoading(true);
    final result = await _authService.resetPassword(email);
    _setLoading(false);
    return result;
  }
}
