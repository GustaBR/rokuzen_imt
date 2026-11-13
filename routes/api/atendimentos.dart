import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mysql_dart/mysql_dart.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final String terapeuta;
  final String unidade;
  final String paciente;
  final String servico;
  final String duracao;
  final DateTime? inicio;

  try {
    final dados = await context.request.json() as Map<String, dynamic>;
    terapeuta = dados['terapeuta'] as String? ?? '';
    unidade = dados['unidade'] as String? ?? '';
    paciente = dados['paciente'] as String? ?? '';
    servico = dados['servico'] as String? ?? '';
    duracao = dados['duracao'] as String? ?? '';
    inicio = DateTime.tryParse(dados['inicio'] as String? ?? '');
  } catch (_) {
    return _erro(HttpStatus.badRequest, 'Dados inválidos');
  }

  if ([terapeuta, unidade, paciente, servico, duracao].any((v) => v.isEmpty) ||
      inicio == null) {
        return _erro(HttpStatus.badRequest, 'Preencha todos os campos');
      }

  final minutos = _emMinutos(duracao);
  if (minutos == null || minutos <= 0) {
    return _erro(HttpStatus.badRequest, 'Duração inválida');
  }

  final fim = inicio.add(Duration(minutes: minutos));

  final pool = context.read<MySQLConnectionPool>();
  final valores = {
    'terapeuta': terapeuta,
    'unidade': unidade,
    'paciente': paciente,
    'servico': servico,
    'duracao': duracao,
    'inicio': _formatarDataHora(inicio),
    'fim': _formatarDataHora(fim),
  };

  try {
    final preco = await pool.execute(
      '''
      SELECT tvr_002_c AS valor, tvr_004_c AS valor_terapeuta
      FROM tvr
      WHERE tpr_ukey = :servico AND tvr_001_c = :duracao
      LIMIT 1
      ''',
      valores,
    );

    if(preco.rows.isEmpty) {
      return _erro(
        HttpStatus.badRequest,
        'Duração não encontrada para o serviço',
      );
    }

    final turno = await pool.execute(
      '''
      SELECT COUNT(*) AS total FROM events
      WHERE title = :terapeuta
        AND terapeuta = 'S' AND adm = 'S'
        AND und_ukey = :unidade
        AND `start` <= :inicio AND `end` >= :fim
      ''',
      valores,
    );
    if ((turno.rows.first.typedColByName<int>('total') ?? 0) == 0) {
      return _erro(
        HttpStatus.conflict,
        'Esse horário está fora do seu turno na escala',
      );
    }

    final conflitos = await pool.execute(
      '''
      SELECT
        (SELECT COUNT(*) FROM atd
          WHERE usr_ukey = :terapeuta
            AND atd_002_c < :fim AND atd_003_c > :inicio)
      +
      (SELECT COUNT(*) FROM maua_atendimento_particular
        WHERE usr_ukey = :terapeuta
          AND inicio < :fim AND fim > :inicio)
      AS total
      ''',
      valores,
    );

    if ((conflitos.rows.first.typedColByName<int>('total') ?? 0) > 0) {
      return _erro(HttpStatus.conflict, 'Já existe um atendimento nesse horário');
    }

    final linhaPreco = preco.rows.first;
    await pool.execute(
      '''
      INSERT INTO atd
        (atd_ukey, und_ukey, cli_ukey, tpr_ukey, usr_ukey,
        atd_001_c, atd_002_c, atd_003_c, atd_004_c, atd_029_c)
      VALUES
        (:ukey, :unidade, :paciente, :servico, :terapeuta,
        :minutos, :inicio, :fim, :valor, :valor_terapeuta)
        ''',
        {
          ...valores,
          'ukey': _gerarUkey(),
          'minutos': minutos,
          'valor': linhaPreco.typedColByName<String>('valor'),
          'valor_terapeuta': linhaPreco.typedColByName<String>('valor_terapeuta'),
        },
    );
    return Response.json(statusCode: HttpStatus.created, body: {'ok' : true});
  } catch (e, stackTrace) {
    stderr
      ..writeln('Erro ao marcar atendimento: $e')
      ..writeln(stackTrace);
    return _erro(HttpStatus.internalServerError, 'Erro interno no servidor');
  }
}

int? _emMinutos(String duracao) {
  final texto = duracao.toLowerCase().replaceAll(' ', '');
  final comHoras = RegExp(r'^(\d+)h(\d+)?').firstMatch(texto);
  if (comHoras != null) {
    return int.parse(comHoras[1]!) * 60 + int.parse(comHoras[2] ?? '0');
  }
  final numero = RegExp(r'\d+').firstMatch(texto);
  return numero == null ? null : int.parse(numero[0]!);
}

String _gerarUkey() {
  final agora = DateTime.now().microsecondsSinceEpoch;
  final segundos = agora ~/ 1000000;
  final microssegundos = agora % 1000000;
  return segundos.toRadixString(16).padLeft(8, '0') +
      microssegundos.toRadixString(16).padLeft(5, '0');
}

String _formatarDataHora(DateTime data) {
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${data.year}-${doisDigitos(data.month)}-${doisDigitos(data.day)} '
      '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}:00';
}

Response _erro(int status, String mensagem) =>
    Response.json(statusCode: status, body: {'erro': mensagem});