import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';
import 'package:pi_20262_imt/database/selos.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final cliente = context.request.uri.queryParameters['cliente'] ?? '';
  if (cliente.isEmpty) {
    return _erro(HttpStatus.badRequest, 'Informe o cliente');
  }

  final pool = context.read<MySQLConnectionPool>();
  final filtro = {'cliente': cliente};

  try {
    final saldo = await saldoDeSelos(pool, cliente);

    
    final resumo = await pool.execute(
      '''
      SELECT
        (SELECT COUNT(*) FROM atd
          WHERE cli_ukey = :cliente AND atd_002_c < NOW()) AS sessoes,
        (SELECT COUNT(*) FROM maua_resgate
          WHERE cli_ukey = :cliente) AS resgates,
        COALESCE(
          (SELECT DATE_FORMAT(MIN(atd_002_c), '%Y-%m-%d') FROM atd
            WHERE cli_ukey = :cliente),
          (SELECT DATE_FORMAT(criado_em, '%Y-%m-%d') FROM maua_cli_acesso
            WHERE cli_ukey = :cliente)
        ) AS desde
      ''',
      filtro,
    );

    
    final proximaSessao = await pool.execute(
      '''
      SELECT
        DATE_FORMAT(a.atd_002_c, '%Y-%m-%dT%H:%i:%s') AS inicio,
        t.tpr_001_c AS servico,
        u.und_001_c AS unidade
      FROM atd a
      LEFT JOIN tpr t ON t.tpr_ukey = a.tpr_ukey
      LEFT JOIN und u ON u.und_ukey = a.und_ukey
      WHERE a.cli_ukey = :cliente AND a.atd_002_c >= NOW()
      ORDER BY a.atd_002_c
      LIMIT 1
      ''',
      filtro,
    );

    
    final historico = await pool.execute(
      '''
      SELECT
        DATE_FORMAT(a.atd_002_c, '%Y-%m-%dT%H:%i:%s') AS data,
        t.tpr_001_c AS servico
      FROM atd a
      LEFT JOIN tpr t ON t.tpr_ukey = a.tpr_ukey
      WHERE a.cli_ukey = :cliente AND a.atd_002_c < NOW()
      ORDER BY a.atd_002_c DESC
      LIMIT 30
      ''',
      filtro,
    );

    
    final proxima = await pool.execute(
      '''
      SELECT nome, selos FROM maua_recompensa
      WHERE ativo = 'S' AND selos > :saldo
      ORDER BY selos
      LIMIT 1
      ''',
      {'saldo': saldo},
    );

    final linhaResumo = resumo.rows.first;

    return Response.json(
      body: {
        'saldo': saldo,
        'sessoes': linhaResumo.typedColByName<int>('sessoes'),
        'resgates': linhaResumo.typedColByName<int>('resgates'),
        'desde': linhaResumo.typedColByName<String>('desde'),
        'proxima': proxima.rows.isEmpty
            ? null
            : {
                'nome': proxima.rows.first.typedColByName<String>('nome'),
                'selos': proxima.rows.first.typedColByName<int>('selos'),
              },
        'proximaSessao': proximaSessao.rows.isEmpty
            ? null
            : {
                'inicio': proximaSessao.rows.first.typedColByName<String>('inicio'),
                'servico': proximaSessao.rows.first.typedColByName<String>('servico'),
                'unidade': proximaSessao.rows.first.typedColByName<String>('unidade'),
              },
        'historico': [
          for (final linha in historico.rows)
            {
              'data': linha.typedColByName<String>('data'),
              'servico': linha.typedColByName<String>('servico'),
            },
        ],
      },
    );
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao buscar selos: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});
