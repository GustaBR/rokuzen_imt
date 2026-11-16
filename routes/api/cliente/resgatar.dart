import 'dart:io';
import 'dart:math';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';
import 'package:pi_20262_imt/database/selos.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final String cliente;
  final int? recompensaId;
  try {
    final dados = await context.request.json() as Map<String, dynamic>;
    cliente = dados['cliente'] as String? ?? '';
    recompensaId = dados['recompensa'] as int?;
  } catch (_) {
    return _erro(HttpStatus.badRequest, 'Dados inválidos');
  }

  if (cliente.isEmpty || recompensaId == null) {
    return _erro(HttpStatus.badRequest, 'Informe o cliente e a recompensa');
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    final recompensa = await pool.execute(
      "SELECT nome, selos FROM maua_recompensa WHERE id = :id AND ativo = 'S'",
      {'id': recompensaId},
    );
    if (recompensa.rows.isEmpty) {
      return _erro(HttpStatus.notFound, 'Recompensa não encontrada');
    }

    final nome = recompensa.rows.first.typedColByName<String>('nome');
    final custo = recompensa.rows.first.typedColByName<int>('selos')!;

    // O saldo é conferido aqui no servidor, e não só no app
    final saldo = await saldoDeSelos(pool, cliente);
    if (saldo < custo) {
      return _erro(HttpStatus.conflict, 'Você ainda não tem selos suficientes');
    }

    final codigo = await _gerarCodigo(pool);

    await pool.execute(
      '''
      INSERT INTO maua_resgate (cli_ukey, recompensa_id, selos, codigo)
      VALUES (:cliente, :recompensa, :selos, :codigo)
      ''',
      {
        'cliente': cliente,
        'recompensa': recompensaId,
        'selos': custo,
        'codigo': codigo,
      },
    );

    return Response.json(
      statusCode: HttpStatus.created,
      body: {'codigo': codigo, 'recompensa': nome},
    );
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao resgatar recompensa: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

/// Código fácil de ler em voz alta na recepção, ex.: RKZ-4F2A9C.
/// Sem as letras/números que se confundem (0 e O, 1 e I).
Future<String> _gerarCodigo(MySQLConnectionPool pool) async {
  const caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final aleatorio = Random.secure();

  for (var tentativa = 0; tentativa < 5; tentativa++) {
    final codigo = 'RKZ-${List.generate(
      6,
      (_) => caracteres[aleatorio.nextInt(caracteres.length)],
    ).join()}';

    final existe = await pool.execute(
      'SELECT 1 FROM maua_resgate WHERE codigo = :codigo LIMIT 1',
      {'codigo': codigo},
    );
    if (existe.rows.isEmpty) return codigo;
  }

  throw Exception('Não foi possível gerar um código único');
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});
