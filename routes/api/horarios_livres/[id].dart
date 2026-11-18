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
  final valores = {'id': idNumero, 'terapeuta': terapeuta};

  try {
    final particulares = await pool.execute(
      '''
      SELECT COUNT(*) AS total
      FROM maua_horario_livre h
      JOIN maua_atendimento_particular p
        ON p.usr_ukey = h.usr_ukey
       AND p.inicio >= h.inicio
       AND p.fim <= h.fim
      WHERE h.id = :id AND h.usr_ukey = :terapeuta
      ''',
      valores,
    );

    if ((particulares.rows.first.typedColByName<int>('total') ?? 0) > 0) {
      return _erro(
        HttpStatus.conflict,
        'Esse horário livre tem atendimentos particulares. '
        'Remova-os antes.',
      );
    }

    final resultado = await pool.execute(
      'DELETE FROM maua_horario_livre '
      'WHERE id = :id AND usr_ukey = :terapeuta',
      valores,
    );

    if (resultado.affectedRows == BigInt.zero) {
      return _erro(HttpStatus.notFound, 'Horário livre não encontrado');
    }

    return Response.json(body: {'ok': true});
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao remover horário livre: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});
