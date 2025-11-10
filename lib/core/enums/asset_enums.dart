enum AssetType {
  currency,
  gold,
  stock,
  cash,
  bankAccount,
  creditCard,
  loan,
}

extension AssetTypeExtension on AssetType {
  String get displayName {
    switch (this) {
      case AssetType.currency:
        return 'Currency';
      case AssetType.gold:
        return 'Gold';
      case AssetType.stock:
        return 'Stock';
      case AssetType.cash:
        return 'Cash';
      case AssetType.bankAccount:
        return 'Bank Account';
      case AssetType.creditCard:
        return 'Credit Card';
      case AssetType.loan:
        return 'Loan';
    }
  }

  bool get isLiability {
    switch (this) {
      case AssetType.loan:
      case AssetType.creditCard:
        return true;
      default:
        return false;
    }
  }

  bool get isAsset => !isLiability;
}
