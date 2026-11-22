import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final String terapeuta;
  final String unidade;
  final List<(DateTime, DateTime)> periodos;
  try {
    final dados = await context.request.json() as Map<String, dynamic>;
    terapeuta = dados['terapeuta'] as String? ?? '';
    unidade = dados['unidade'] as String? ?? '';
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

  if (terapeuta.isEmpty || unidade.isEmpty) {
    return _erro(HttpStatus.badRequest, 'Informe o terapeuta e a unidade');
  }
  if (periodos.isEmpty) {
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
        'Cada horário disponível precisa ser num dia só',
      );
    }
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    final unidadeDoTerapeuta = await pool.execute(
      '''
      SELECT 1 FROM usr WHERE usr_ukey = :terapeuta AND und_ukey = :unidade
      UNION
      SELECT 1 FROM usrXund WHERE usr_ukey = :terapeuta AND und_ukey = :unidade
      LIMIT 1
      ''',
      {'terapeuta': terapeuta, 'unidade': unidade},
    );
    if (unidadeDoTerapeuta.rows.isEmpty) {
      return _erro(HttpStatus.badRequest, 'Unidade inválida para este terapeuta');
    }

    final ultimaCor = await pool.execute(
      '''
      SELECT color FROM events
      WHERE title = :terapeuta AND terapeuta = 'S' AND color IS NOT NULL
      ORDER BY `start` DESC
      LIMIT 1
      ''',
      {'terapeuta': terapeuta},
    );
    final cor = ultimaCor.rows.isEmpty
        ? null
        : ultimaCor.rows.first.typedColByName<String>('color');

    final criados = <String>[];
    final ignorados = <Map<String, String>>[];

    for (final (inicio, fim) in periodos) {
      final valores = {
        'terapeuta': terapeuta,
        'unidade': unidade,
        'cor': cor,
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
        INSERT INTO events
          (title, color, `start`, `end`, und_ukey,
           terapeuta, adm, gerente, carregamento)
        VALUES
          (:terapeuta, :cor, :inicio, :fim, :unidade,
           'S', 'S', 'N', 'N')
        ''',
        valores,
      );
      criados.add(inicio.toIso8601String());
    }

    if (criados.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {
          'erro': ignorados.length == 1
              ? ignorados.first['motivo']
              : 'Nenhum dia foi adicionado: todos já têm escala nesse '
                  'horário ou já passaram',
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
      ..writeln('Erro ao informar disponibilidade: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

Future<String?> _motivoParaNaoMarcar(
  MySQLConnectionPool pool,
  Map<String, String?> valores,
  DateTime inicio,
) async {
  if (inicio.isBefore(DateTime.now())) return 'Esse horário já passou';

  final escala = await pool.execute(
    '''
    SELECT 1 FROM events
    WHERE title = :terapeuta AND terapeuta = 'S' AND adm = 'S'
      AND `start` < :fim AND `end` > :inicio
    LIMIT 1
    ''',
    valores,
  );
  if (escala.rows.isNotEmpty) {
    return 'Você já tem horário disponível nesse período';
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