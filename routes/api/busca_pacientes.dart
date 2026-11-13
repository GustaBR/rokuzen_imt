import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final termo = (context.request.uri.queryParameters['termo'] ?? '').trim();
  if (termo.length < 3) {
    return Response.json(body: <Object>[]);
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    final resultado = await pool.execute(
      '''
      SELECT
        cli_ukey,
        cli_004_c AS nome,
        DATE_FORMAT(cli_017_c, '%d/%m/%Y') AS nascimento,
        cli_012_c AS celular
      FROM cli
      WHERE cli_004_c LIKE :termo
      ORDER BY cli_004_c
      LIMIT 10
      ''',
      {'termo': '%$termo%'},
    );

    return Response.json(
      body: [
        for (final linha in resultado.rows)
        {
          'id': linha.typedColByName<String>('cli_ukey'),
          'nome': linha.typedColByName<String>('nome'),
          'nascimento': linha.typedColByName<String>('nascimento'),
          'celular': linha.typedColByName<String>('celular'),
        },
      ],
    );
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro na busca de pacientes: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});