import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }


final String login;
final String senha;
try {
  final dados = await context.request.json() as Map<String, dynamic>;
  login = (dados['login'] as String? ?? '').trim();
  senha = dados['senha'] as String? ?? '';
} catch (_) {
  return _erro(HttpStatus.badRequest, 'Dados inválidos');
}

if (login.isEmpty || senha.isEmpty) {
  return _erro(HttpStatus.badRequest, 'Informe usuário e senha');
}

final pool = context.read<MySQLConnectionPool>();

try {
  final resultado = await pool.execute(
    'SELECT usr_ukey, und_ukey, usr_002_c, usr_003_c, usr_010_c '
    'FROM usr WHERE usr_001_c = :login LIMIT 1',
    {'login': login},
  );

  if (resultado.rows.isEmpty) {
    return _credenciaisInvalidas();
  }

  final usuario = resultado.rows.first;

  if (usuario.typedColByName<String>('usr_003_c') != senha) {
    return _credenciaisInvalidas();
  }

  final id = usuario.typedColByName<String>('usr_ukey')!;
  final unidadePrincipal = usuario.typedColByName<String>('und_ukey');

  final unidades = await pool.execute(
    '''
    SELECT und_ukey, und_001_c FROM und
    WHERE und_ukey = :unidade
    OR und_ukey IN (SELECT und_ukey FROM usrXund WHERE usr_ukey = :id)
    ORDER BY und_001_c
    ''',
    {'unidade': unidadePrincipal, 'id': id},
  );

  return Response.json(
    body: {
      'id': id,
      'nome': usuario.typedColByName<String>('usr_002_c'),
      'tipo': usuario.typedColByName<String>('usr_010_c'),
      'unidadePrincipal': unidadePrincipal,
      'unidades': [
        for (final unidade in unidades.rows)
        {
          'id': unidade.typedColByName<String>('und_ukey'),
          'nome': unidade.typedColByName<String>('und_001_c'),
        },
      ],
    },
  );
} catch (e, stackTrace) {
  stderr
    ..writeln('Erro no login: $e')
    ..writeln(stackTrace);
  return _erro(HttpStatus.internalServerError,'Erro interno no servidor');
  }
}

Response _credenciaisInvalidas() =>
    _erro(HttpStatus.unauthorized, 'Usuário ou senha incorretos');

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});