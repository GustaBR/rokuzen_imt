
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

/// GET /api/cliente/meus_dados_cliente?cliente=ID
/// PUT /api/cliente/meus_dados_cliente?cliente=ID
///
/// Consulta e atualiza os dados cadastrais do cliente.
Future<Response> onRequest(RequestContext context) async {
  final metodo = context.request.method;

  if (metodo != HttpMethod.get && metodo != HttpMethod.put) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final cliente = context.request.uri.queryParameters['cliente'] ?? '';

  if (cliente.isEmpty) {
    return _erro(HttpStatus.badRequest, 'Informe o cliente');
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    if (metodo == HttpMethod.get) {
      return await _buscarDados(pool, cliente);
    }

    return await _atualizarDados(context, pool, cliente);
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao processar dados do cliente: $e')
      ..writeln(stackTrace);

    return _erro(
      HttpStatus.internalServerError,
      'Erro interno no servidor',
    );
  }
}

/// Consulta os dados cadastrais do cliente.
Future<Response> _buscarDados(
  MySQLConnectionPool pool,
  String cliente,
) async {
  final resultado = await pool.execute(
    '''
    SELECT
      c.cli_004_c AS nome,
      c.cli_010_c AS genero,
      c.cli_040_c AS cpf,
      DATE_FORMAT(c.cli_017_c, '%Y-%m-%d') AS nascimento,
      c.cli_012_c AS telefone,
      c.cli_001_c AS emailContato,
      c.cli_041_c AS rua,
      c.cli_042_c AS numero,
      c.cli_043_c AS complemento,
      c.cli_044_c AS bairro,
      c.cli_045_c AS cidade,
      c.cli_046_c AS uf,
      c.cli_047_c AS cep,
      a.email AS emailConta
    FROM cli c
    LEFT JOIN maua_cli_acesso a
      ON a.cli_ukey = c.cli_ukey
    WHERE c.cli_ukey = :cliente
    LIMIT 1
    ''',
    {'cliente': cliente},
  );

  if (resultado.rows.isEmpty) {
    return _erro(HttpStatus.notFound, 'Cliente não encontrado');
  }

  final linha = resultado.rows.first;

  String? campo(String coluna) {
    final valor = linha.typedColByName<String>(coluna)?.trim();

    return (valor == null || valor.isEmpty) ? null : valor;
  }

  return Response.json(
    body: {
      'dadosPessoais': {
        'nome': campo('nome'),
        'genero': campo('genero'),
        'cpf': campo('cpf'),
        'nascimento': campo('nascimento'),
        'telefone': campo('telefone'),
        'emailContato': campo('emailContato'),
      },
      'endereco': {
        'rua': campo('rua'),
        'numero': campo('numero'),
        'complemento': campo('complemento'),
        'bairro': campo('bairro'),
        'cidade': campo('cidade'),
        'uf': campo('uf'),
        'cep': campo('cep'),
      },
      'dadosConta': {
        'email': campo('emailConta'),
      },
    },
  );
}

/// Atualiza os dados pessoais e o endereço do cliente.
Future<Response> _atualizarDados(
  RequestContext context,
  MySQLConnectionPool pool,
  String cliente,
) async {
  final dynamic corpo;

  try {
    corpo = jsonDecode(await context.request.body());
  } catch (_) {
    return _erro(HttpStatus.badRequest, 'Corpo da requisição inválido');
  }

  if (corpo is! Map<String, dynamic>) {
    return _erro(HttpStatus.badRequest, 'Formato de dados inválido');
  }

  String? campo(String chave) {
    if (!corpo.containsKey(chave)) return null;

    final valor = corpo[chave];

    if (valor == null) return null;
    if (valor is! String) {
      throw FormatException('O campo $chave deve ser um texto');
    }

    final texto = valor.trim();
    return texto.isEmpty ? null : texto;
  }

  String? nascimento;

  try {
    nascimento = _formatarNascimento(campo('nascimento'));
  } on FormatException catch (e) {
    return _erro(HttpStatus.badRequest, e.message);
  }

  // Confirma que o cliente existe antes de atualizar.
  final existente = await pool.execute(
    'SELECT cli_ukey FROM cli WHERE cli_ukey = :cliente LIMIT 1',
    {'cliente': cliente},
  );

  if (existente.rows.isEmpty) {
    return _erro(HttpStatus.notFound, 'Cliente não encontrado');
  }

  await pool.execute(
    '''
    UPDATE cli
    SET
      cli_004_c = COALESCE(:nome, cli_004_c),
      cli_010_c = COALESCE(:genero, cli_010_c),
      cli_040_c = COALESCE(:cpf, cli_040_c),
      cli_017_c = COALESCE(:nascimento, cli_017_c),
      cli_012_c = COALESCE(:telefone, cli_012_c),
      cli_001_c = COALESCE(:emailContato, cli_001_c),
      cli_041_c = COALESCE(:rua, cli_041_c),
      cli_042_c = COALESCE(:numero, cli_042_c),
      cli_043_c = COALESCE(:complemento, cli_043_c),
      cli_044_c = COALESCE(:bairro, cli_044_c),
      cli_045_c = COALESCE(:cidade, cli_045_c),
      cli_046_c = COALESCE(:uf, cli_046_c),
      cli_047_c = COALESCE(:cep, cli_047_c)
    WHERE cli_ukey = :cliente
    ''',
    {
      'cliente': cliente,
      'nome': campo('nome'),
      'genero': campo('genero'),
      'cpf': campo('cpf'),
      'nascimento': nascimento,
      'telefone': campo('telefone'),
      'emailContato': campo('emailContato'),
      'rua': campo('rua'),
      'numero': campo('numero'),
      'complemento': campo('complemento'),
      'bairro': campo('bairro'),
      'cidade': campo('cidade'),
      'uf': campo('uf'),
      'cep': campo('cep'),
    },
  );

  return Response.json(
    body: {
      'mensagem': 'Dados atualizados com sucesso',
    },
  );
}

/// Aceita DD/MM/AAAA ou AAAA-MM-DD e retorna AAAA-MM-DD.
String? _formatarNascimento(String? valor) {
  if (valor == null) return null;

  DateTime? data;

  if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(valor)) {
    final partes = valor.split('/');
    data = DateTime.tryParse(
      '${partes[2]}-${partes[1]}-${partes[0]}',
    );
  } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(valor)) {
    data = DateTime.tryParse(valor);
  }

  if (data == null ||
      data.year.toString().padLeft(4, '0') !=
          (valor.contains('/') ? valor.split('/')[2] : valor.split('-')[0]) ||
      data.month !=
          int.parse(valor.contains('/') ? valor.split('/')[1] : valor.split('-')[1]) ||
      data.day !=
          int.parse(valor.contains('/') ? valor.split('/')[0] : valor.split('-')[2])) {
    throw const FormatException('Data de nascimento inválida');
  }

  return '${data.year.toString().padLeft(4, '0')}-'
      '${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';
}

Response _erro(int status, String mensagem) {
  return Response.json(
    statusCode: status,
    body: {'erro': mensagem},
  );
}
