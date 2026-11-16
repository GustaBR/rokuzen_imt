import 'dart:io';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

/// Se o CPF e a data de nascimento baterem com um paciente que já existe
/// na tabela cli, liga a conta a ele; se não, cria o paciente.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final String nome;
  final String email;
  final String celular;
  final String cpf;
  final DateTime? nascimento;
  final String senha;
  try {
    final dados = await context.request.json() as Map<String, dynamic>;
    nome = _texto(dados['nome']);
    email = _texto(dados['email']).toLowerCase();
    celular = _texto(dados['celular']);
    cpf = _texto(dados['cpf']).replaceAll(RegExp('[^0-9]'), '');
    nascimento = DateTime.tryParse(_texto(dados['nascimento']));
    senha = dados['senha'] as String? ?? '';
  } catch (_) {
    return _erro(HttpStatus.badRequest, 'Dados inválidos');
  }

  if (nome.isEmpty ||
      !email.contains('@') ||
      celular.isEmpty ||
      cpf.length != 11 ||
      nascimento == null) {
    return _erro(HttpStatus.badRequest, 'Preencha todos os campos corretamente');
  }
  if (nome.length > 150 || email.length > 150 || celular.length > 20) {
    return _erro(HttpStatus.badRequest, 'Texto muito longo');
  }
  if (senha.length < 6) {
    return _erro(
      HttpStatus.badRequest,
      'A senha precisa ter pelo menos 6 caracteres',
    );
  }

  final pool = context.read<MySQLConnectionPool>();
  final dataNascimento = _formatarData(nascimento);

  try {
    final emailUsado = await pool.execute(
      'SELECT 1 FROM maua_cli_acesso WHERE email = :email LIMIT 1',
      {'email': email},
    );
    if (emailUsado.rows.isNotEmpty) {
      return _erro(HttpStatus.conflict, 'Já existe uma conta com esse e-mail');
    }

    
    final existente = await pool.execute(
      '''
      SELECT cli_ukey, DATE_FORMAT(cli_017_c, '%Y-%m-%d') AS nascimento
      FROM cli
      WHERE cli_040_c = :cpf
      LIMIT 1
      ''',
      {'cpf': cpf},
    );

    final String clienteId;
    if (existente.rows.isNotEmpty) {
      final paciente = existente.rows.first;

      if (paciente.typedColByName<String>('nascimento') != dataNascimento) {
        return _erro(
          HttpStatus.conflict,
          'Os dados não conferem com o cadastro deste CPF. Procure a recepção.',
        );
      }

      clienteId = paciente.typedColByName<String>('cli_ukey')!;

      final jaTemConta = await pool.execute(
        'SELECT 1 FROM maua_cli_acesso WHERE cli_ukey = :id LIMIT 1',
        {'id': clienteId},
      );
      if (jaTemConta.rows.isNotEmpty) {
        return _erro(HttpStatus.conflict, 'Este CPF já tem uma conta. Faça login.');
      }
    } else {
      // Paciente novo: mesmas colunas da tela Cadastrar Paciente
      clienteId = _gerarUkey();
      await pool.execute(
        '''
        INSERT INTO cli (cli_ukey, cli_001_c, cli_004_c, cli_012_c, cli_017_c, cli_040_c)
        VALUES (:id, :email, :nome, :celular, :nascimento, :cpf)
        ''',
        {
          'id': clienteId,
          'email': email,
          'nome': nome,
          'celular': celular,
          'nascimento': dataNascimento,
          'cpf': cpf,
        },
      );
    }

    await pool.execute(
      '''
      INSERT INTO maua_cli_acesso (cli_ukey, email, senha_hash)
      VALUES (:id, :email, :hash)
      ''',
      {
        'id': clienteId,
        'email': email,
        'hash': BCrypt.hashpw(senha, BCrypt.gensalt()),
      },
    );

    return Response.json(statusCode: HttpStatus.created, body: {'ok': true});
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro no cadastro de cliente: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

String _gerarUkey() {
  final aleatorio = Random.secure();
  return List.generate(
    10,
    (_) => aleatorio.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

String _formatarData(DateTime data) =>
    '${data.year}-${data.month.toString().padLeft(2, '0')}-'
    '${data.day.toString().padLeft(2, '0')}';

String _texto(Object? valor) => valor?.toString().trim() ?? '';

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});
