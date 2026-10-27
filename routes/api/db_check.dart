import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';
import 'dart:io';

Future<Response> onRequest(RequestContext context) async {
  final pool = context.read<MySQLConnectionPool>();

  try {
    
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nome VARCHAR(50) NOT NULL
      )
    ''');

    await pool.execute(
      'INSERT INTO usuarios (nome) VALUES (:nome)',
      {'nome': 'Felipe'},
    );

    final result = await pool.execute(
      'SELECT id, nome FROM usuarios',
    );

    for (final row in result.rows) {
      final id = row.typedColAt<int>(0);
      final nome = row.typedColAt<String>(1);

      print('ID: $id, Nome: $nome');
    }

    return Response.json(
      body: {
        'connected': result.rows.first.typedColAt<String>(1) == "Felipe",
        'message': 'MySQL connection successful',
      },
    );
  } catch (e, stackTrace) {
    stderr.writeln('Database connection failed: $e');
    stderr.writeln(stackTrace);

    return Response.json(
      statusCode: 500,
      body: {'error': 'Database connection failed'},
    );
  }
}
