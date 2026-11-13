import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

/// GET /api/duracoes?servico=TPR_UKEY
/// Durações disponíveis para o serviço (tabela tvr).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final servico = context.request.uri.queryParameters['servico'] ?? '';
  if (servico.isEmpty) {
    return _erro(HttpStatus.badRequest, 'Informe o serviço');
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    final resultado = await pool.execute(
      'SELECT tvr_001_c FROM tvr WHERE tpr_ukey = :servico '
      'ORDER BY tvr_001_c + 0',

      {'servico': servico},
    );

    return Response.json(
      body: [
        for (final linha in resultado.rows)
          linha.typedColByName<String>('tvr_001_c'),
      ],
    );
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao buscar durações: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});
