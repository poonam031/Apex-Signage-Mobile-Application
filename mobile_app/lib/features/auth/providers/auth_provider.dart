import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  String get role => _user?['role'] ?? 'FIELD_BOY';

  Future<void> checkAuth() async {
    final cachedUser = await LocalStorage.getUser();
    if (cachedUser != null) {
      _user = cachedUser;
      notifyListeners();
    }
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.post('/auth/login', {
      'identifier': identifier,
      'password': password,
    });

    _isLoading = false;

    if (response.success && response.data != null) {
      final data = response.data;
      _user = data['user'];
      await LocalStorage.saveTokens(data['accessToken'], data['refreshToken']);
      await LocalStorage.saveUser(_user!);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message ?? 'Invalid username or password';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await LocalStorage.clearAuth();
    _user = null;
    notifyListeners();
  }
}
