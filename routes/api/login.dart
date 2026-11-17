import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

/// POST /api/login
/// Recebe {login, senha}, onde login é o e-mail.
/// Terapeutas e clientes têm contas próprias do app, com senha em hash:
/// maua_terapeuta_acesso (ligada ao usr) e maua_cli_acesso (ligada ao cli).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final String email;
  final String senha;
  try {
    final dados = await context.request.json() as Map<String, dynamic>;
    email = (dados['login'] as String? ?? '').trim().toLowerCase();
    senha = dados['senha'] as String? ?? '';
  } catch (_) {
    return _erro(HttpStatus.badRequest, 'Dados inválidos');
  }

  if (email.isEmpty || senha.isEmpty) {
    return _erro(HttpStatus.badRequest, 'Informe e-mail e senha');
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    // Primeiro tenta como terapeuta; se o e-mail não for de terapeuta,
    // tenta como cliente
    return await _loginTerapeuta(pool, email, senha) ??
        await _loginCliente(pool, email, senha) ??
        _credenciaisInvalidas();
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro no login: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

/// Devolve null se o e-mail não for de nenhum terapeuta.
Future<Response?> _loginTerapeuta(
  MySQLConnectionPool pool,
  String email,
  String senha,
) async {
  final resultado = await pool.execute(
    '''
    SELECT a.usr_ukey, a.senha_hash, u.und_ukey, u.usr_002_c AS nome,
           u.usr_010_c AS tipo
    FROM maua_terapeuta_acesso a
    JOIN usr u ON u.usr_ukey = a.usr_ukey
    WHERE a.email = :email
    LIMIT 1
    ''',
    {'email': email},
  );

  if (resultado.rows.isEmpty) return null;

  final terapeuta = resultado.rows.first;
  if (!BCrypt.checkpw(senha, terapeuta.typedColByName<String>('senha_hash')!)) {
    return _credenciaisInvalidas();
  }

  final id = terapeuta.typedColByName<String>('usr_ukey')!;
  final unidadePrincipal = terapeuta.typedColByName<String>('und_ukey');

  // Unidades do terapeuta: a principal (usr.und_ukey) e as extras (usrXund)
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
      'nome': terapeuta.typedColByName<String>('nome'),
      'tipo': terapeuta.typedColByName<String>('tipo'),
      'perfil': 'terapeuta',
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
}

/// Devolve null se o e-mail não for de nenhum cliente.
Future<Response?> _loginCliente(
  MySQLConnectionPool pool,
  String email,
  String senha,
) async {
  final resultado = await pool.execute(
    '''
    SELECT a.cli_ukey, a.senha_hash, c.cli_004_c AS nome
    FROM maua_cli_acesso a
    JOIN cli c ON c.cli_ukey = a.cli_ukey
    WHERE a.email = :email
    LIMIT 1
    ''',
    {'email': email},
  );

  if (resultado.rows.isEmpty) return null;

  final cliente = resultado.rows.first;
  if (!BCrypt.checkpw(senha, cliente.typedColByName<String>('senha_hash')!)) {
    return _credenciaisInvalidas();
  }

  return Response.json(
    body: {
      'id': cliente.typedColByName<String>('cli_ukey'),
      'nome': cliente.typedColByName<String>('nome'),
      'tipo': null,
      'perfil': 'cliente',
      'unidadePrincipal': null,
      'unidades': <Object>[],
    },
  );
}

/// Mesma mensagem para e-mail inexistente e senha errada,
/// para não revelar quais e-mails têm conta.
Response _credenciaisInvalidas() =>
    _erro(HttpStatus.unauthorized, 'E-mail ou senha incorretos');

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});
