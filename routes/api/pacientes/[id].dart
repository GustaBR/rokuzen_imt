import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final pool = context.read<MySQLConnectionPool>();

  try {
    final resultado = await pool.execute(
      '''
      SELECT
        cli_004_c AS nome,
        DATE_FORMAT(cli_017_c, '%Y-%m-%d') AS nascimento,
        cli_012_c AS celular,
        cli_018_c AS profissao,
        cli_039_c AS observacoes,
        cli_022_c AS esta_com_dor, cli_023_c AS qual_dor, cli_024_c AS escala_dor,
        cli_026_c AS pressao, cli_027_c AS pressao_medicada,
        cli_028_c AS osteoporose, cli_029_c AS osteopenia,
        cli_030_c AS hernia, cli_031_c AS hernia_local,
        cli_032_c AS problemas_renais,
        cli_033_c AS cancer, cli_034_c AS cancer_onde,
        cli_036_c AS gravida, cli_037_c AS gravida_meses,
        cli_048_c AS trombose
      FROM cli
      WHERE cli_ukey = :id
      LIMIT 1
      ''',
      {'id': id},
    );

    if (resultado.rows.isEmpty) {
      return _erro(HttpStatus.notFound, 'Paciente não encontrado');
    }

    final linha = resultado.rows.first;

    String? campo(String coluna) {
      final valor = linha.typedColByName<String>(coluna)?.trim();
      return (valor == null || valor.isEmpty) ? null : valor;
    }

    const fichaDeSaude = [
      ('Está com dor', 'esta_com_dor', ['qual_dor', 'escala_dor']),
      ('Pressão', 'pressao', <String>[]),
      ('Pressão medicada', 'pressao_medicada', <String>[]),
      ('Osteoporose', 'osteoporose', <String>[]),
      ('Osteopenia', 'osteopenia', <String>[]),
      ('Hérnia de disco', 'hernia', ['hernia_local']),
      ('Problemas renais', 'problemas_renais', <String>[]),
      ('Câncer', 'cancer', ['cancer_onde']),
      ('Gravidez', 'gravida', ['gravida_meses']),
      ('Trombose', 'trombose', <String>[]),
    ];

    final saude = [
      for (final (rotulo, coluna, detalhes) in fichaDeSaude)
      if (campo(coluna) != null && !_ehNao(campo(coluna)!))
       {
        'rotulo': rotulo,
        'valor': _descrever(campo(coluna)!, [
          for (final detalhe in detalhes)
            if (campo(detalhe) != null) campo(detalhe)!,
        ]),
        'alerta': _ehSim(campo(coluna)!),
       },
    ];

    return Response.json(
      body: {
        'nome': campo('nome'),
        'nascimento': campo('nascimento'),
        'celular': campo('celular'),
        'profissao': campo('profissao'),
        'observacoes': campo('observacoes'),
        'saude': saude,
      },
    );
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao buscar paciente: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

bool _ehSim(String valor) => ['S', 'SIM'].contains(valor.toUpperCase());

bool _ehNao(String valor) => ['N', 'NAO', 'NÃO'].contains(valor.toUpperCase());

String _descrever(String valor, List<String> detalhes) {
  final texto = _ehSim(valor) ? 'Sim' : valor;
  if (detalhes.isEmpty || !_ehSim(valor)) return texto;
  return '$texto: ${detalhes.join(' · ')}';
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});