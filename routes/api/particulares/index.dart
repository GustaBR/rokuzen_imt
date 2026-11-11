import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';


Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final String terapeuta;
  final String cliente;
  final String? observacao;
  final DateTime? inicio;
  final DateTime? fim;

  try {
    final dados = await context.request.json() as Map<String, dynamic>;
    terapeuta = dados['terapeuta'] as String? ?? '';
    cliente = (dados['cliente'] as String? ?? '').trim();
    final textoObservacao = (dados['observacao'] as String? ?? '').trim();
    observacao = textoObservacao.isEmpty ? null : textoObservacao;
    inicio = DateTime.tryParse(dados['inicio'] as String? ?? '');
    fim = DateTime.tryParse(dados['fim'] as String? ?? '');
  } catch (_) {
    return _erro(HttpStatus.badRequest, 'Dados inválidos');
  }

  if (terapeuta.isEmpty || cliente.isEmpty || inicio == null || fim == null) {
    return _erro(HttpStatus.badRequest, 'Informe cliente, início e fim');
  }

  if (cliente.length > 100 || (observacao?.length ?? 0) > 255) {
    return _erro(HttpStatus.badRequest, 'Texto muito longo');
  }

  if (!fim.isAfter(inicio)) {
    return _erro(
      HttpStatus.badRequest,
      'O horário final precisa ser depois do inicial'
    );
  }

  final pool = context.read<MySQLConnectionPool>();
  final valores = {
    'terapeuta': terapeuta,
    'cliente': cliente,
    'observacao': observacao,
    'inicio': _formatarDataHora(inicio),
    'fim': _formatarDataHora(fim),
  };

  try {
    final conflitos = await pool.execute(
      '''
      SELECT
        (SELECT COUNT(*) FROM atd
          WHERE usr_ukey = :terapeuta
            AND atd_002_c < :fim AND atd_003_c > :inicio)
      +
      (SELECT COUNT(*) FROM maua_atendimento_particular
        WHERE usr_ukey = :terapeuta
          AND inicio < :fim AND fim > :inicio)
      AS total
      ''',
      valores,
    );

    if ((conflitos.rows.first.typedColByName<int>('total') ?? 0) > 0) {
      return _erro(HttpStatus.conflict, 'Já existe um atendimento nesse horário');
    }

    await pool.execute(
      '''
      INSERT INTO maua_atendimento_particular
        (usr_ukey, cliente, observacao, inicio, fim)
      VALUES (:terapeuta, :cliente, :observacao, :inicio, :fim)
      ''',
      valores,
    );
    
    return Response.json(statusCode: HttpStatus.created, body: {'ok': true});
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao criar atendimento particular: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

String _formatarDataHora(DateTime data) {
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${data.year}-${doisDigitos(data.month)}-${doisDigitos(data.day)} '
      '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}:00';
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});