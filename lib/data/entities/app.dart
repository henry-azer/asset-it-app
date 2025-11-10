class App {
  final bool isInitialized;
  final String version;
  final DateTime lastAccessDate;
  final String themeMode;

  const App({
    required this.isInitialized,
    required this.version,
    required this.lastAccessDate,
    required this.themeMode,
  });

  Map<String, dynamic> toMap() {
    return {
      'isInitialized': isInitialized,
      'version': version,
      'lastAccessDate': lastAccessDate.toIso8601String(),
      'themeMode': themeMode,
    };
  }

  factory App.fromMap(Map<String, dynamic> map) {
    return App(
      isInitialized: map['isInitialized'] ?? false,
      version: map['version'] ?? '1.0.0',
      lastAccessDate: DateTime.parse(map['lastAccessDate'] ?? DateTime.now().toIso8601String()),
      themeMode: map['themeMode'] ?? 'system',
    );
  }

  App copyWith({
    bool? isInitialized,
    String? version,
    DateTime? lastAccessDate,
    String? themeMode,
  }) {
    return App(
      isInitialized: isInitialized ?? this.isInitialized,
      version: version ?? this.version,
      lastAccessDate: lastAccessDate ?? this.lastAccessDate,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
