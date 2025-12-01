import 'package:flutter/material.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/enums/asset_enums.dart';
import 'package:asset_it/core/utils/app_colors.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/core/utils/number_formatter.dart';
import 'package:asset_it/data/entities/asset.dart';
import 'package:asset_it/data/entities/asset_with_values.dart';

class AssetsListItemCard extends StatelessWidget {
  final AssetWithValues assetWithValue;
  final bool isDark;
  final VoidCallback onTap;

  const AssetsListItemCard({
    super.key,
    required this.assetWithValue,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final asset = assetWithValue.asset;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getTypeColor(asset.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getAssetIcon(asset),
                color: _getTypeColor(asset.type),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitle(asset),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (_getSubtitle(asset) != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _getSubtitle(asset)!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAssetValue(assetWithValue),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getValueColor(assetWithValue.asset.type, assetWithValue.currentValue, isDark),
                  ),
                ),
                if (assetWithValue.asset.type == AssetType.loan &&
                    assetWithValue.asset.loanInterestRate != null && 
                    assetWithValue.asset.loanInterestRate! > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    NumberFormatter.formatWithSymbol(assetWithValue.purchaseValue.abs()),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${assetWithValue.asset.loanInterestRate!.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
                if (assetWithValue.gainLoss != 0 && 
                    assetWithValue.asset.type != AssetType.loan && 
                    assetWithValue.asset.type != AssetType.creditCard) ...[  
                  const SizedBox(height: 2),
                  Text(
                    NumberFormatter.formatWithSymbol(assetWithValue.purchaseValue),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        NumberFormatter.formatGainLoss(assetWithValue.gainLoss),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: assetWithValue.gainLoss > 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                      if (assetWithValue.purchaseValue != 0) ...[
                        Text(
                          ' (${assetWithValue.gainLossPercentage >= 0 ? '+' : ''}${assetWithValue.gainLossPercentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: assetWithValue.gainLoss > 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(Asset asset) {
    switch (asset.type) {
      case AssetType.gold:
        return '${asset.goldKarat ?? ''} ${AppStrings.goldLabel.tr}';
      case AssetType.stock:
        return asset.stockSymbol ?? AppStrings.stockLabel.tr;
      case AssetType.bankAccount:
        return asset.bankName ?? AppStrings.bankAccount.tr;
      case AssetType.creditCard:
        return asset.bankName ?? AppStrings.creditCard.tr;
      case AssetType.loan:
        return asset.bankName ?? AppStrings.loan.tr;
      case AssetType.currency:
        return asset.currency ?? AppStrings.currency.tr;
      case AssetType.cash:
        return AppStrings.cash.tr;
    }
  }

  String? _getSubtitle(Asset asset) {
    if (asset.type == AssetType.gold && asset.goldGrams != null && asset.goldGrams! > 0) {
      return '${NumberFormatter.formatNumber(asset.goldGrams!, decimalPlaces: 2)}g';
    } else if (asset.type == AssetType.stock && asset.stockShares != null && asset.stockShares! > 0) {
      return '${NumberFormatter.formatNumber(asset.stockShares!, decimalPlaces: 2)} ${AppStrings.shares.tr}';
    } else if (asset.type == AssetType.bankAccount && asset.bankAccountType != null) {
      return asset.bankAccountType;
    } else if (asset.type == AssetType.creditCard) {
      final limit = asset.creditLimit ?? 0;
      return '${AppStrings.limit.tr} ${NumberFormatter.formatWithSymbol(limit, showDecimals: false)}';
    } else if ((asset.type == AssetType.currency || asset.type == AssetType.cash) && asset.currencyAmount != null && asset.currencyAmount! > 0) {
      return '${NumberFormatter.formatNumber(asset.currencyAmount!, decimalPlaces: 2)} ${asset.currency ?? ''}';
    }
    return null;
  }

  IconData _getAssetIcon(Asset asset) {
    if (asset.type == AssetType.gold) {
      return Icons.diamond_outlined;
    } else if (asset.type == AssetType.stock) {
      return Icons.show_chart;
    } else if (asset.type == AssetType.bankAccount) {
      return Icons.account_balance_outlined;
    } else if (asset.type == AssetType.creditCard) {
      return Icons.credit_card_outlined;
    } else if (asset.type == AssetType.loan) {
      return Icons.description_outlined;
    } else if (asset.type == AssetType.cash) {
      return Icons.payments_outlined;
    }
    return Icons.attach_money_outlined;
  }

  String _formatAssetValue(AssetWithValues assetWithValue) {
    final asset = assetWithValue.asset;
    final value = assetWithValue.currentValue;
    
    if (asset.type == AssetType.creditCard || asset.type == AssetType.loan) {
      final absValue = value.abs();
      return '-${NumberFormatter.formatWithSymbol(absValue)}';
    }
    
    return NumberFormatter.formatWithSymbol(value);
  }

  Color _getValueColor(AssetType type, double value, bool isDark) {
    if (type == AssetType.creditCard || type == AssetType.loan) {
      return AppColors.error;
    }
    return isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  }

  Color _getTypeColor(AssetType type) {
    switch (type) {
      case AssetType.currency:
        return AppColors.currencyColor;
      case AssetType.gold:
        return AppColors.goldColor;
      case AssetType.bankAccount:
        return AppColors.bankColor;
      case AssetType.cash:
        return AppColors.cashColor;
      case AssetType.creditCard:
        return AppColors.creditCardColor;
      case AssetType.loan:
        return AppColors.loanColor;
      case AssetType.stock:
        return AppColors.stockColor;
    }
  }
}
