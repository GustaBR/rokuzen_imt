import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final parametros = context.request.uri.queryParameters;
  final terapeuta = parametros['terapeuta'] ?? '';
  final inicio = DateTime.tryParse(parametros['inicio'] ?? '');
  final fim = DateTime.tryParse(parametros['fim'] ?? '');

  if (terapeuta.isEmpty || inicio == null || fim == null) {
    return _erro(HttpStatus.badRequest, 'Informe terapeuta, inicio e fim');
  }

  final pool = context.read<MySQLConnectionPool>();
  final filtros = {
    'terapeuta': terapeuta,
    'inicio': _formatarData(inicio),
    'fim': _formatarData(fim),
  };

  try {
    final sessoes = await pool.execute(
      '''
      SELECT
        DATE_FORMAT(a.atd_002_c, '%Y-%m-%dT%H:%i:%s') AS inicio,
        DATE_FORMAT(a.atd_003_c, '%Y-%m-%dT%H:%i:%s') AS fim,
        c.cli_004_c AS cliente,
        t.tpr_001_c AS servico
      FROM atd a
      LEFT JOIN cli c ON c.cli_ukey = a.cli_ukey
      LEFT JOIN tpr t ON t.tpr_ukey = a.tpr_ukey
      WHERE a.usr_ukey = :terapeuta
        AND a.atd_002_c >= :inicio
        AND a.atd_002_c < :fim
      ORDER BY a.atd_002_c
      ''',
      filtros,
    );

    final escala = await pool.execute(
      '''
      SELECT
        DATE_FORMAT(`start`, '%Y-%m-%dT%H:%i:%s') AS inicio,
        DATE_FORMAT(`end`, '%Y-%m-%dT%H:%i:%s') AS fim
      FROM events
      WHERE title = :terapeuta
        AND terapeuta = 'S'
        AND adm = 'S'
        AND `start` >= :inicio
        AND `start` < :fim
      ORDER BY `start`
      ''',
      filtros,
    );

    return Response.json(
      body: {
        'sessoes': [
          for (final linha in sessoes.rows)
          {
            'inicio': linha.typedColByName<String>('inicio'),
            'fim': linha.typedColByName<String>('fim'),
            'cliente': linha.typedColByName<String>('cliente'),
            'servico': linha.typedColByName<String>('servico'),
          },
        ],
        'escala': [
          for (final linha in escala.rows)
          {
            'inicio': linha.typedColByName<String>('inicio'),
            'fim': linha.typedColByName<String>('fim'),
          },
        ],
      },
    );
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro na agenda: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

String _formatarData(DateTime data) =>
    '${data.year}-${data.month.toString().padLeft(2, '0')}-'
    '${data.day.toString().padLeft(2, '0')}';

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});