import 'package:asset_it/data/entities/asset.dart';
import 'package:asset_it/features/finance/providers/finance_provider.dart';
import 'package:asset_it/core/enums/asset_enums.dart';

class AssetWithValues {
  final Asset asset;
  final double currentValue;
  final double purchaseValue;
  
  AssetWithValues({
    required this.asset,
    required this.currentValue,
    required this.purchaseValue,
  });
  
  double get gainLoss => currentValue - purchaseValue;
  
  double get gainLossPercentage => 
    purchaseValue != 0 ? (gainLoss / purchaseValue) * 100 : 0;
  
  bool get isProfit => gainLoss >= 0;
  
  static AssetWithValues fromAsset(Asset asset, FinanceProvider financeProvider) {
    double calculatedValue = asset.initialValue;
    double? calculatedPurchaseValue;
    
    switch (asset.type) {
      case AssetType.gold:
        final goldKarat = asset.goldKarat ?? '';
        final grams = asset.goldGrams ?? 0;
        final currentPricePerGram = financeProvider.getGoldFinance(goldKarat) ?? 0;
        final purchasePricePerGram = asset.goldPricePerGram ?? currentPricePerGram;
        calculatedValue = grams * currentPricePerGram;
        calculatedPurchaseValue = grams * purchasePricePerGram;
        break;
        
      case AssetType.stock:
        final symbol = asset.stockSymbol;
        final shares = asset.stockShares ?? 0;
        if (symbol != null) {
          final currentStockPrice = financeProvider.getFinanceByCode(symbol)?.value ?? asset.stockPricePerShare ?? 0;
          final purchaseStockPrice = asset.stockPricePerShare ?? currentStockPrice;
          calculatedValue = shares * currentStockPrice;
          calculatedPurchaseValue = shares * purchaseStockPrice;
        }
        break;
        
      case AssetType.currency:
        final currency = asset.currency ?? '';
        final currencyAmount = asset.currencyAmount ?? asset.initialValue;
        final currentRate = financeProvider.getCurrencyRate(currency);
        final purchaseRate = asset.purchaseRate ?? currentRate;
        
        if (currentRate > 0) {
          calculatedValue = currencyAmount * currentRate;
          calculatedPurchaseValue = currencyAmount * purchaseRate;
        } else {
          calculatedValue = currencyAmount;
          calculatedPurchaseValue = currencyAmount;
        }
        break;
        
      case AssetType.bankAccount:
        calculatedValue = asset.initialValue;
        calculatedPurchaseValue = asset.initialValue;
        break;
        
      case AssetType.cash:
        calculatedValue = asset.initialValue;
        calculatedPurchaseValue = asset.initialValue;
        break;
        
      case AssetType.creditCard:
        final creditUsed = asset.creditUsed ?? 0;
        calculatedValue = -creditUsed;
        break;
        
      case AssetType.loan:
        final loanAmount = asset.initialValue.abs();
        final interestRate = asset.loanInterestRate ?? 0;
        final totalWithInterest = loanAmount * (1 + (interestRate / 100));
        calculatedValue = -totalWithInterest;
        calculatedPurchaseValue = -loanAmount;
        break;
        
      default:
        calculatedValue = asset.initialValue;
        calculatedPurchaseValue = asset.initialValue;
    }
    
    return AssetWithValues(
      asset: asset,
      currentValue: calculatedValue,
      purchaseValue: calculatedPurchaseValue ?? asset.initialValue,
    );
  }
}
