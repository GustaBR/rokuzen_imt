import 'dart:io';

import 'package:mysql_dart/mysql_dart.dart';

class DatabaseConnection {
  final String host;
  final int port;
  final String database;
  final String user;
  final String password;
  final int maxConnections;

  DatabaseConnection({
    required this.host,
    required this.port,
    required this.database,
    required this.user,
    required this.password,
    this.maxConnections = 10,
  });

  MySQLConnectionPool createPool() {
    final securityContext = SecurityContext(
      withTrustedRoots: true,
    );

    securityContext.setTrustedCertificates(
      'certs/ca.pem',
    );

    return MySQLConnectionPool(
      host: host,
      port: port,
      userName: user,
      password: password,
      databaseName: database,
      maxConnections: maxConnections,
      secure: true,
      securityContext: securityContext,
    );
  }
}