import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return _erro(HttpStatus.methodNotAllowed, "Método não permitido.");
  }

  if (id.isEmpty) {
    return _erro(HttpStatus.badRequest, "ID não informado.");
  }

  final pool = context.read<MySQLConnectionPool>();

  final resultado = await pool.execute(
    '''
      SELECT
        atd.usr_ukey,
        atd.cli_ukey,
        atd.atd_002_c,
        atd.atd_003_c,
        atd.atd_004_c,
        cli.cli_004_c 
      FROM atd
      LEFT JOIN cli ON atd.cli_ukey = cli.cli_ukey
      WHERE atd.usr_ukey = :id;
    ''',
    {'id': id}    
  );


  final atendimentos = <Map<String, dynamic>>[];

  for (final row in resultado.rows) {
    final inicio = row.typedColByName<String>('atd_002_c');
    final fim = row.typedColByName<String>('atd_003_c');
    final valor = row.typedColByName<String>('atd_004_c');
    final cliente = row.typedColByName<String>('cli_004_c');

    
    final valorValidado =
        valor == null ? null : double.tryParse(valor);

    atendimentos.add({
      'inicio': inicio,
      'fim': fim,
      'valor': valorValidado,
      'cliente': cliente ?? 'Cliente não informado',
    });
  }


  return Response.json(
    statusCode: HttpStatus.ok,
    body: {
      'mensagem': "Os atendimentos foram carregados com sucesso.",
      'atendimentos': atendimentos
    }
  );
}

Response _erro(int status, String mensagem) {
  return Response.json(
    statusCode: status,
    body: {'erro': mensagem},
  );
}