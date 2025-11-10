import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:asset_it/app.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/injection_container.dart' as di;

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await AppLocalization.initialize();
  await di.init();
  runApp(const AssetItApp());
}
