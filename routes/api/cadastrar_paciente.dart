
import 'dart:io';
import 'dart:math';
import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return _erro(HttpStatus.methodNotAllowed, 'Método não permitido');
  }

  Map<String, dynamic> dados;

  try {
    dados = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    return _erro(HttpStatus.badRequest, 'Dados inválidos');
  }

  final nome = _texto(dados['nome']);
  final telefone = _texto(dados['telefone']);
  final dataNascimento = _texto(dados['dataNascimento']);

  if (nome.isEmpty || telefone.isEmpty || dataNascimento.isEmpty) {
    return _erro(
      HttpStatus.badRequest,
      'Informe nome, telefone e data de nascimento',
    );
  }

  if (nome.length > 150 || telefone.length > 20) {
    return _erro(HttpStatus.badRequest, 'Um ou mais campos são muito longos');
  }

  DateTime nascimento;

  try {
    nascimento = DateTime.parse(dataNascimento);
  } catch (_) {
    return _erro(
      HttpStatus.badRequest,
      'Data de nascimento inválida. Utilize YYYY-MM-DD',
    );
  }

  if (nascimento.isAfter(DateTime.now())) {
    return _erro(
      HttpStatus.badRequest,
      'A data de nascimento não pode ser futura',
    );
  }

  final email = _texto(dados['email']);
  final genero = _texto(dados['genero']);
  final cpf = _texto(dados['cpf']).replaceAll(RegExp(r'[^0-9]'), '');
  final observacoes = _texto(dados['observacoes']);

  if (email.length > 150 ||
      genero.length > 2 ||
      cpf.length > 12 ||
      observacoes.length > 65535) {
    return _erro(HttpStatus.badRequest, 'Um ou mais campos são muito longos');
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    final id = await _gerarIdUnico(pool);

    await pool.execute(
      '''
      INSERT INTO cli (
        cli_ukey,
        cli_001_c,
        cli_004_c,
        cli_010_c,
        cli_012_c,
        cli_017_c,
        cli_039_c,
        cli_040_c
      ) VALUES (
        :id,
        :email,
        :nome,
        :genero,
        :telefone,
        :nascimento,
        :observacoes,
        :cpf
      )
      ''',
      {
        'id': id,
        'email': email.isEmpty ? null : email,
        'nome': nome,
        'genero': genero.isEmpty ? null : genero,
        'telefone': telefone,
        'nascimento': DateTime(
          nascimento.year,
          nascimento.month,
          nascimento.day,
        ),
        'observacoes': observacoes.isEmpty ? null : observacoes,
        'cpf': cpf.isEmpty ? null : cpf,
      },
    );

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'mensagem': 'Paciente cadastrado com sucesso',
        'id': id,
      },
    );
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao cadastrar paciente: $e')
      ..writeln(stackTrace);

    return _erro(
      HttpStatus.internalServerError,
      'Não foi possível cadastrar o paciente',
    );
  }
}

Future<String> _gerarIdUnico(MySQLConnectionPool pool) async {
  final random = Random.secure();

  for (var tentativa = 0; tentativa < 5; tentativa++) {
    final id = List.generate(
      10,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();

    final resultado = await pool.execute(
      'SELECT cli_ukey FROM cli WHERE cli_ukey = :id LIMIT 1',
      {'id': id},
    );

    if (resultado.rows.isEmpty) {
      return id;
    }
  }

  throw Exception('Não foi possível gerar um identificador único');
}

String _texto(dynamic valor) {
  return valor?.toString().trim() ?? '';
}

Response _erro(int status, String mensagem) {
  return Response.json(
    statusCode: status,
    body: {'erro': mensagem},
  );
}
