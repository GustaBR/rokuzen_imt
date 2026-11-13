
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
    );
  }

  final id = context.request.uri.queryParameters['id'];

  if (id == null || id.isEmpty) {
    return _erro(
      HttpStatus.badRequest,
      'ID do terapeuta não informado',
    );
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    final resultado = await pool.execute(
      '''
      SELECT
        usr_ukey,
        usr_002_c,
        usr_011_c,
        usr_012_c,
        usr_013_c,
        usr_014_c,
        usr_015_c,
        usr_016_c,
        usr_017_c,
        usr_018_c,
        usr_019_c,
        usr_023_c,
        usr_027_c
      FROM usr
      WHERE usr_ukey = :id
      LIMIT 1
      ''',
      {'id': id},
    );

    if (resultado.rows.isEmpty) {
      return _erro(
        HttpStatus.notFound,
        'Terapeuta não encontrado',
      );
    }

    final terapeuta = resultado.rows.first;

    return Response.json(
      body: {
        'id': terapeuta.typedColByName<String>('usr_ukey'),
        'nome': terapeuta.typedColByName<String>('usr_002_c'),
        'endereco': terapeuta.typedColByName<String>('usr_011_c'),
        'numero': terapeuta.typedColByName<String>('usr_012_c'),
        'complemento': terapeuta.typedColByName<String>('usr_013_c'),
        'bairro': terapeuta.typedColByName<String>('usr_014_c'),
        'cidade': terapeuta.typedColByName<String>('usr_015_c'),
        'estado': terapeuta.typedColByName<String>('usr_016_c'),
        'cep': terapeuta.typedColByName<String>('usr_017_c'),
        'dataNascimento': terapeuta.typedColByName<String>('usr_018_c'),
        'email': terapeuta.typedColByName<String>('usr_019_c'),
        'celular': terapeuta.typedColByName<String>('usr_023_c'),
        'foto': terapeuta.typedColByName<String>('usr_027_c'),
      },
    );

// Tratamento de erros no back
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao buscar perfil: $e')
      ..writeln(stackTrace);

    return _erro(
      HttpStatus.internalServerError,
      'Erro interno no servidor',
    );
  }
}

Response _erro(int status, String mensagem) {
  return Response.json(
    statusCode: status,
    body: {'erro': mensagem},
  );
}
