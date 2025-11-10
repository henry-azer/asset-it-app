class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String textDirection;

  LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    this.textDirection = 'ltr',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageOption &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'LanguageOption(code: $code, name: $name)';
}
