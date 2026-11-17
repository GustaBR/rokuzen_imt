import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final String email;
  final String cpf;
  final DateTime? nascimento;
  final String senha;
  try {
    final dados = await context.request.json() as Map<String, dynamic>;
    email = (dados['email'] as String? ?? '').trim().toLowerCase();
    cpf = (dados['cpf'] as String? ?? '').replaceAll(RegExp('[^0-9]'), '');
    nascimento = DateTime.tryParse(dados['nascimento'] as String? ?? '');
    senha = dados['senha'] as String? ?? '';
  } catch (_) {
    return _erro(HttpStatus.badRequest, 'Dados inválidos');
  }

  if (!email.contains('@') || cpf.length != 11 || nascimento == null) {
    return _erro(HttpStatus.badRequest, 'Preencha todos os campos corretamente');
  }
  if (email.length > 150) {
    return _erro(HttpStatus.badRequest, 'E-mail muito longo');
  }
  if (senha.length < 6) {
    return _erro(
      HttpStatus.badRequest,
      'A senha precisa ter pelo menos 6 caracteres',
    );
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    // O e-mail não pode estar em uso, nem por terapeuta nem por cliente
    final emailUsado = await pool.execute(
      '''
      SELECT 1 FROM maua_terapeuta_acesso WHERE email = :email
      UNION
      SELECT 1 FROM maua_cli_acesso WHERE email = :email
      LIMIT 1
      ''',
      {'email': email},
    );
    if (emailUsado.rows.isNotEmpty) {
      return _erro(HttpStatus.conflict, 'Já existe uma conta com esse e-mail');
    }

    // Terapeuta da Rokuzen com esse CPF (com ou sem pontuação no banco)
    final terapeuta = await pool.execute(
      '''
      SELECT usr_ukey, DATE_FORMAT(usr_018_c, '%Y-%m-%d') AS nascimento
      FROM usr
      WHERE usr_010_c = '3'
        AND REPLACE(REPLACE(REPLACE(usr_026_c, '.', ''), '-', ''), ' ', '') = :cpf
      LIMIT 1
      ''',
      {'cpf': cpf},
    );

    // Mesma mensagem para "CPF não encontrado" e "data errada",
    // para não revelar quais CPFs são de terapeutas
    if (terapeuta.rows.isEmpty ||
        terapeuta.rows.first.typedColByName<String>('nascimento') !=
            _formatarData(nascimento)) {
      return _erro(
        HttpStatus.conflict,
        'Não encontramos um terapeuta com esses dados. Procure a secretaria.',
      );
    }

    final usrUkey = terapeuta.rows.first.typedColByName<String>('usr_ukey')!;

    final jaTemConta = await pool.execute(
      'SELECT 1 FROM maua_terapeuta_acesso WHERE usr_ukey = :id LIMIT 1',
      {'id': usrUkey},
    );
    if (jaTemConta.rows.isNotEmpty) {
      return _erro(HttpStatus.conflict, 'Você já tem uma conta. Faça login.');
    }

    await pool.execute(
      '''
      INSERT INTO maua_terapeuta_acesso (usr_ukey, email, senha_hash)
      VALUES (:id, :email, :hash)
      ''',
      {
        'id': usrUkey,
        'email': email,
        'hash': BCrypt.hashpw(senha, BCrypt.gensalt()),
      },
    );

    return Response.json(statusCode: HttpStatus.created, body: {'ok': true});
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro no cadastro de terapeuta: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

String _formatarData(DateTime data) =>
    '${data.year}-${data.month.toString().padLeft(2, '0')}-'
    '${data.day.toString().padLeft(2, '0')}';

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});
