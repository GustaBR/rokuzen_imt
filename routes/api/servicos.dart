import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final unidade = context.request.uri.queryParameters['unidade'] ?? '';
  if (unidade.isEmpty) {
    return _erro(HttpStatus.badRequest, 'Informe a unidade');
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    final resultado = await pool.execute(
      '''
      SELECT tpr_ukey, tpr_001_c
      FROM tpr
      WHERE und_ukey = :unidade AND tpr_005_c = 'S'
      ORDER BY tpr_001_c
      ''',
      {'unidade': unidade},
    );

    return Response.json(
      body: [
        for (final linha in resultado.rows)
        {
          'id': linha.typedColByName<String>('tpr_ukey'),
          'nome': linha.typedColByName<String>('tpr_001_c'),
        },
      ],
    );
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao buscar serviços: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});