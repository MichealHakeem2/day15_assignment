import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:shopping_app/core/database/sqflite_helper.dart';
import 'package:shopping_app/core/di/service_locator.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => getIt.init();

@module
abstract class RegisterModule {
  @lazySingleton
  http.Client get client => http.Client();

  @lazySingleton
  SqfliteHelper get sqfliteHelper => SqfliteHelper.instance;
}
