import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:asset_it/data/datasources/user_local_datasource.dart';
import 'package:asset_it/data/entities/user.dart';

class AuthProvider with ChangeNotifier {
  late UserLocalDataSource _userLocalDataSource;
  bool _isAuthenticated = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _userPassword;
  User? _currentUser;

  AuthProvider() {
    _userLocalDataSource = GetIt.instance<UserLocalDataSource>();
    _loadAuthenticationStatus();
  }

  bool get isAuthenticated => _isAuthenticated;

  bool get isLoading => _isLoading;

  bool get obscurePassword => _obscurePassword;

  String? get userPassword => _userPassword;

  User? get currentUser => _currentUser;

  void _loadAuthenticationStatus() async {
    try {
      _isAuthenticated = await _userLocalDataSource.isAuthenticated();
      _userPassword = await _userLocalDataSource.getUserPassword();
      _currentUser = await _userLocalDataSource.getUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading authentication status: $e');
    }
  }

  Future<bool> login(String password) async {
    _setLoading(true);
    try {
      final storedPassword = await _userLocalDataSource.getUserPassword();

      if (storedPassword == password) {
        await _userLocalDataSource.setAuthenticated(true);
        _isAuthenticated = true;
        _userPassword = password;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String username, String password) async {
    _setLoading(true);
    try {
      await _userLocalDataSource.setUserPassword(password);
      await _userLocalDataSource.setAuthenticated(true);

      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        password: password,
        isAuthenticated: true,
        isOnboardingCompleted: true,
        createdDate: DateTime.now(),
      );

      await _userLocalDataSource.setUser(user);

      _isAuthenticated = true;
      _userPassword = password;
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    _setLoading(true);
    try {
      final storedPassword = await _userLocalDataSource.getUserPassword();

      if (storedPassword != currentPassword) {
        return false;
      }

      await _userLocalDataSource.setUserPassword(newPassword);

      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(password: newPassword);
        await _userLocalDataSource.setUser(updatedUser);
        _currentUser = updatedUser;
      }

      _userPassword = newPassword;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Change password error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUsername(String newUsername) async {
    _setLoading(true);
    try {
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(username: newUsername);
        await _userLocalDataSource.setUser(updatedUser);
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Update username error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserProfile({
    String? newUsername,
    String? currentPassword,
    String? newPassword,
  }) async {
    _setLoading(true);
    try {
      if (_currentUser == null) {
        return false;
      }

      User updatedUser = _currentUser!;

      if (newUsername != null && newUsername.isNotEmpty) {
        updatedUser = updatedUser.copyWith(username: newUsername);
      }

      if (currentPassword != null &&
          newPassword != null &&
          newPassword.isNotEmpty) {
        final storedPassword = await _userLocalDataSource.getUserPassword();

        if (storedPassword != currentPassword) {
          return false;
        }

        updatedUser = updatedUser.copyWith(password: newPassword);
        await _userLocalDataSource.setUserPassword(newPassword);
        _userPassword = newPassword;
      }

      await _userLocalDataSource.setUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update user profile error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await _userLocalDataSource.setAuthenticated(false);
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<bool> hasPassword() async {
    try {
      final password = await _userLocalDataSource.getUserPassword();
      return password != null && password.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking master password: $e');
      return false;
    }
  }

  Future<bool> hasUser() async {
    try {
      final user = await _userLocalDataSource.getUser();
      return user != null;
    } catch (e) {
      debugPrint('Error checking user: $e');
      return false;
    }
  }

  Future<bool> isUserOnboarded() async {
    try {
      final isOnboarded = await _userLocalDataSource.isOnboardingCompleted();
      return isOnboarded;
    } catch (e) {
      debugPrint('Error checking first time user: $e');
      return false;
    }
  }

  Future<bool> isUserCreated() async {
    try {
      final user = await _userLocalDataSource.getUser();
      return user != null;
    } catch (e) {
      debugPrint('Error checking first time user: $e');
      return false;
    }
  }

  Future<bool> loginWithBiometric() async {
    _setLoading(true);
    try {
      final storedPassword = await _userLocalDataSource.getUserPassword();

      if (storedPassword != null && storedPassword.isNotEmpty) {
        await _userLocalDataSource.setAuthenticated(true);
        _isAuthenticated = true;
        _userPassword = storedPassword;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Biometric login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearUserData() async {
    try {
      await _userLocalDataSource.clearUserData();
      _isAuthenticated = false;
      _userPassword = null;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }
}
