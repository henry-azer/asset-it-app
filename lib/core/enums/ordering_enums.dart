enum OrderingType {
  manual,
  dateAdded,
  value,
  name,
}

extension OrderingTypeExtension on OrderingType {
  String get name {
    switch (this) {
      case OrderingType.manual:
        return 'manual';
      case OrderingType.dateAdded:
        return 'date_added';
      case OrderingType.value:
        return 'value';
      case OrderingType.name:
        return 'name';
    }
  }

  String get displayName {
    switch (this) {
      case OrderingType.manual:
        return 'Manual';
      case OrderingType.dateAdded:
        return 'Date Added';
      case OrderingType.value:
        return 'Value';
      case OrderingType.name:
        return 'Name';
    }
  }

  static OrderingType fromString(String value) {
    switch (value) {
      case 'manual':
        return OrderingType.manual;
      case 'date_added':
        return OrderingType.dateAdded;
      case 'value':
        return OrderingType.value;
      case 'name':
        return OrderingType.name;
      default:
        return OrderingType.dateAdded;
    }
  }
}