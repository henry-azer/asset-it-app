enum FinanceType {
  currency,
  gold,
  stock;

  String get label {
    switch (this) {
      case FinanceType.currency:
        return 'Currency';
      case FinanceType.gold:
        return 'Gold';
      case FinanceType.stock:
        return 'Stock';
    }
  }

  String get icon {
    switch (this) {
      case FinanceType.currency:
        return '💱';
      case FinanceType.gold:
        return '🥇';
      case FinanceType.stock:
        return '📈';
    }
  }
}
