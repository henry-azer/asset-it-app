class AppLocalStorageKeys {
  // Database
  static const String databaseName = 'asset_it.db';
  
  // Tables
  static const String currencyChoicesTable = 'currency_choices';
  static const String assetsTable = 'assets';
  static const String usersTable = 'users';
  static const String financesTable = 'finances';
  static const String baseCurrenciesTable = 'base_currencies';
  static const String salariesTable = 'salaries';
  
  // User Preferences
  static const String activeCurrencyChoiceId = 'active_currency_choice_id';
  static const String currentUserId = 'current_user_id';
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';
  static const String biometricEnabled = 'biometric_enabled';
  static const String hasCompletedOnboarding = 'has_completed_onboarding';
  static const String currentCurrency = 'current_currency';
  
  // API Settings
  static const String useManualPrices = 'use_manual_prices';
  static const String useManualFinances = 'use_manual_finances';
  static const String manualExchangeRates = 'manual_exchange_rates';
  static const String manualGoldPrices = 'manual_gold_prices';
  static const String manualGoldFinances = 'manual_gold_finances';
  static const String manualStockPrices = 'manual_stock_prices';
  static const String manualStockFinances = 'manual_stock_finances';
  static const String lastDataRefresh = 'last_data_refresh';
  
  static const String selectedLanguage = 'selected_language';
  static const String appData = 'app_data';
  static const String lastBackupDate = 'last_backup_date';
  static const String userData = 'user_data';
  static const String password = 'password';
  static const String isAuthenticated = 'is_authenticated';
  static const String isOnboardingCompleted = 'is_onboarding_completed';
  
  // Premium
  static const String isPremium = 'is_premium';
  static const String premiumPurchaseDate = 'premium_purchase_date';
}
