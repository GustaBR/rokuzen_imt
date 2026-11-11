import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final terapeuta = context.request.uri.queryParameters['terapeuta'] ?? '';
  final idNumero = int.tryParse(id);

  if (terapeuta.isEmpty || idNumero == null) {
    return _erro(HttpStatus.badRequest, 'Informe o terapeuta e um id válido');
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    final resultado = await pool.execute(
      'DELETE FROM maua_atendimento_particular '
      'WHERE id = :id AND usr_ukey = :terapeuta',
      {'id': idNumero, 'terapeuta': terapeuta},
    );

    if (resultado.affectedRows == BigInt.zero) {
      return _erro(HttpStatus.notFound, 'Atendimento não encontrado');
    }

    return Response.json(body: {'ok': true});
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao remover atendimento particular: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});