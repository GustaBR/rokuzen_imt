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
    'SELECT * FROM atd WHERE usr_ukey = :id',
    {'id': id}    
  );

  return Response.json(
    statusCode: HttpStatus.ok,
    body: {
      'mensagem': "Os atendimentos foram carregados com sucesso.",
      'atendimentos': List.from(resultado.rows.map((atendimento) => {
        'id': atendimento.typedColByName<String>('atd_ukey'),
        'inicio': atendimento.typedColByName<String>('atd_002_c'),
        'fim': atendimento.typedColByName<String>('atd_003_c'),
      })),
    }
  );
}

Response _erro(int status, String mensagem) {
  return Response.json(
    statusCode: status,
    body: {'erro': mensagem},
  );
}