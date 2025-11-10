import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:asset_it/data/datasources/user_local_datasource.dart';

class OnboardingProvider with ChangeNotifier {
  late UserLocalDataSource _userLocalDataSource;
  bool _isOnboardingCompleted = false;
  int _currentPage = 0;

  OnboardingProvider() {
    _userLocalDataSource = GetIt.instance<UserLocalDataSource>();
    _loadOnboardingStatus();
  }

  bool get isOnboardingCompleted => _isOnboardingCompleted;

  int get currentPage => _currentPage;

  void _loadOnboardingStatus() async {
    try {
      _isOnboardingCompleted =
          await _userLocalDataSource.isOnboardingCompleted();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading onboarding status: $e');
    }
  }

  Future<void> completeOnboarding() async {
    try {
      await _userLocalDataSource.setOnboardingCompleted(true);
      _isOnboardingCompleted = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  Future<void> resetOnboarding() async {
    try {
      await _userLocalDataSource.setOnboardingCompleted(false);
      _isOnboardingCompleted = false;
      _currentPage = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting onboarding: $e');
    }
  }

  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void nextPage() {
    _currentPage++;
    notifyListeners();
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }
}
