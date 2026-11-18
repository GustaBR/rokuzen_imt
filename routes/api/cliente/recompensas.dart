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

  try {
    final saldo = await saldoDeSelos(pool, cliente);

    final catalogo = await pool.execute(
      '''
      SELECT id, nome, descricao, selos
      FROM maua_recompensa
      WHERE ativo = 'S'
      ORDER BY selos
      ''',
    );

    final resgates = await pool.execute(
      '''
      SELECT
        r.codigo,
        r.selos,
        r.usado,
        DATE_FORMAT(r.criado_em, '%Y-%m-%dT%H:%i:%s') AS data,
        c.nome
      FROM maua_resgate r
      JOIN maua_recompensa c ON c.id = r.recompensa_id
      WHERE r.cli_ukey = :cliente
      ORDER BY r.criado_em DESC
      ''',
      {'cliente': cliente},
    );

    return Response.json(
      body: {
        'saldo': saldo,
        'recompensas': [
          for (final linha in catalogo.rows)
            {
              'id': linha.typedColByName<int>('id'),
              'nome': linha.typedColByName<String>('nome'),
              'descricao': linha.typedColByName<String>('descricao'),
              'selos': linha.typedColByName<int>('selos'),
            },
        ],
        'resgates': [
          for (final linha in resgates.rows)
            {
              'codigo': linha.typedColByName<String>('codigo'),
              'nome': linha.typedColByName<String>('nome'),
              'selos': linha.typedColByName<int>('selos'),
              'data': linha.typedColByName<String>('data'),
              'usado': linha.typedColByName<String>('usado') == 'S',
            },
        ],
      },
    );
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao buscar recompensas: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});
