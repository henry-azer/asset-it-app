import 'package:asset_it/core/enums/asset_enums.dart';

class AssetTypeOrdering {
  final String id;
  final String profileId;
  final AssetType assetType;
  final int sortOrder;

  AssetTypeOrdering({
    required this.id,
    required this.profileId,
    required this.assetType,
    required this.sortOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'assetType': assetType.name,
      'sortOrder': sortOrder,
    };
  }

  factory AssetTypeOrdering.fromMap(Map<String, dynamic> map) {
    return AssetTypeOrdering(
      id: map['id'] as String,
      profileId: map['profileId'] as String,
      assetType: AssetType.values.firstWhere(
        (e) => e.name == map['assetType'],
        orElse: () => AssetType.cash,
      ),
      sortOrder: (map['sortOrder'] as int?) ?? 0,
    );
  }

  AssetTypeOrdering copyWith({
    String? id,
    String? profileId,
    AssetType? assetType,
    int? sortOrder,
  }) {
    return AssetTypeOrdering(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      assetType: assetType ?? this.assetType,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
