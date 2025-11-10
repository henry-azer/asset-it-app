import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  int get selectedIndex => _selectedIndex;
  PageController get pageController => _pageController;

  List<String> get pages => ['Dashboard', 'Assets', 'Finance', 'Settings'];
  
  List<IconData> get icons => [
    Icons.lock,
    Icons.vpn_key,
    Icons.settings,
  ];

  void setSelectedIndex(int index) {
    if (index != _selectedIndex && index >= 0 && index < pages.length) {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void onPageChanged(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
