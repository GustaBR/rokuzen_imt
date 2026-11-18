import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

/// POST /api/horarios_livres
/// Recebe {terapeuta, periodos: [{inicio, fim}, ...]}, um período por dia.
/// Marca os que não cruzam com a escala, com atendimentos da Rokuzen nem
/// com outros horários livres, e devolve os que ficaram de fora com o motivo.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final String terapeuta;
  final List<(DateTime, DateTime)> periodos;
  try {
    final dados = await context.request.json() as Map<String, dynamic>;
    terapeuta = dados['terapeuta'] as String? ?? '';
    periodos = [
      for (final item
          in (dados['periodos'] as List).cast<Map<String, dynamic>>())
        (
          DateTime.parse(item['inicio'] as String),
          DateTime.parse(item['fim'] as String),
        ),
    ];
  } catch (_) {
    return _erro(HttpStatus.badRequest, 'Dados inválidos');
  }

  if (terapeuta.isEmpty || periodos.isEmpty) {
    return _erro(HttpStatus.badRequest, 'Escolha pelo menos um dia');
  }
  if (periodos.length > 62) {
    return _erro(HttpStatus.badRequest, 'Escolha no máximo 62 dias por vez');
  }
  for (final (inicio, fim) in periodos) {
    if (!fim.isAfter(inicio)) {
      return _erro(
        HttpStatus.badRequest,
        'O horário final precisa ser depois do inicial',
      );
    }
    if (inicio.year != fim.year ||
        inicio.month != fim.month ||
        inicio.day != fim.day) {
      return _erro(
        HttpStatus.badRequest,
        'Cada horário livre precisa ser num dia só',
      );
    }
  }

  final pool = context.read<MySQLConnectionPool>();
  final criados = <String>[];
  final ignorados = <Map<String, String>>[];

  try {
    for (final (inicio, fim) in periodos) {
      final valores = {
        'terapeuta': terapeuta,
        'inicio': _formatarDataHora(inicio),
        'fim': _formatarDataHora(fim),
      };

      final motivo = await _motivoParaNaoMarcar(pool, valores, inicio);
      if (motivo != null) {
        ignorados.add({'inicio': inicio.toIso8601String(), 'motivo': motivo});
        continue;
      }

      await pool.execute(
        '''
        INSERT INTO maua_horario_livre (usr_ukey, inicio, fim)
        VALUES (:terapeuta, :inicio, :fim)
        ''',
        valores,
      );
      criados.add(inicio.toIso8601String());
    }

    // Nenhum dia deu certo: devolve como erro, com o motivo
    if (criados.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {
          'erro': ignorados.length == 1
              ? ignorados.first['motivo']
              : 'Nenhum dia foi marcado: todos cruzam com o seu turno, '
                  'com atendimentos ou com outros horários livres',
          'ignorados': ignorados,
        },
      );
    }

    return Response.json(
      statusCode: HttpStatus.created,
      body: {'criados': criados, 'ignorados': ignorados},
    );
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao criar horário livre: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

/// Devolve o motivo para não marcar esse período, ou null se estiver livre.
Future<String?> _motivoParaNaoMarcar(
  MySQLConnectionPool pool,
  Map<String, String> valores,
  DateTime inicio,
) async {
  if (inicio.isBefore(DateTime.now())) return 'Esse horário já passou';

  // Dois períodos se cruzam quando um começa antes do outro terminar
  // e termina depois do outro começar
  final conflitos = await pool.execute(
    '''
    SELECT
      (SELECT COUNT(*) FROM events
        WHERE title = :terapeuta AND terapeuta = 'S' AND adm = 'S'
          AND `start` < :fim AND `end` > :inicio) AS escala,
      (SELECT COUNT(*) FROM atd
        WHERE usr_ukey = :terapeuta
          AND atd_002_c < :fim AND atd_003_c > :inicio) AS rokuzen,
      (SELECT COUNT(*) FROM maua_horario_livre
        WHERE usr_ukey = :terapeuta
          AND inicio < :fim AND fim > :inicio) AS livres
    ''',
    valores,
  );

  final linha = conflitos.rows.first;
  if ((linha.typedColByName<int>('escala') ?? 0) > 0) {
    return 'Cruza com o seu turno na Rokuzen';
  }
  if ((linha.typedColByName<int>('rokuzen') ?? 0) > 0) {
    return 'Cruza com um atendimento da Rokuzen';
  }
  if ((linha.typedColByName<int>('livres') ?? 0) > 0) {
    return 'Você já tem um horário livre nesse período';
  }
  return null;
}

String _formatarDataHora(DateTime data) {
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${data.year}-${doisDigitos(data.month)}-${doisDigitos(data.day)} '
      '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}:00';
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});
