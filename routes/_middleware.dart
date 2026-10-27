import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';
import 'package:pi_20262_imt/database/connection.dart';
import 'dart:io';


Handler middleware(Handler handler) {

  final pool = DatabaseConnection(
    host: Platform.environment['DB_HOST']!,
    port: int.parse(Platform.environment['DB_PORT']!),
    database: Platform.environment['DB_NAME']!,
    user: Platform.environment['DB_USER']!,
    password: Platform.environment['DB_PASSWORD']!,
  ).createPool();

  return handler.use(
    provider<MySQLConnectionPool>((context) => pool)
  );
}