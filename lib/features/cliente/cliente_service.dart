import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_config.dart';
import '../../core/sessao.dart';
import '../../core/texto.dart';

class ProximaRecompensa {
  final String nome;
  final int selos;

  const ProximaRecompensa({required this.nome, required this.selos});
}


class SeloGanho {
  final DateTime data;
  final String servico;

  const SeloGanho({required this.data, required this.servico});
}


class ProximaSessao {
  final DateTime inicio;
  final String servico;
  final String? unidade;

  const ProximaSessao({
    required this.inicio,
    required this.servico,
    required this.unidade,
  });
}


class SelosDados {
  final int saldo;
  final int sessoes;
  final int resgates;
  final DateTime? clienteDesde;
  final ProximaRecompensa? proxima;
  final ProximaSessao? proximaSessao;
  final List<SeloGanho> historico;

  const SelosDados({
    required this.saldo,
    required this.sessoes,
    required this.resgates,
    required this.clienteDesde,
    required this.proxima,
    required this.proximaSessao,
    required this.historico,
  });
}


class Recompensa {
  final int id;
  final String nome;
  final String? descricao;
  final int selos;

  const Recompensa({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.selos,
  });
}

class Resgate {
  final String codigo;
  final String nome;
  final int selos;
  final DateTime data;
  final bool usado;

  const Resgate({
    required this.codigo,
    required this.nome,
    required this.selos,
    required this.data,
    required this.usado,
  });
}

class RecompensasDados {
  final int saldo;
  final List<Recompensa> recompensas;
  final List<Resgate> resgates;

  const RecompensasDados({
    required this.saldo,
    required this.recompensas,
    required this.resgates,
  });
}

class ClienteException implements Exception {
  final String mensagem;

  const ClienteException(this.mensagem);
}

class ClienteService {
    Future<SelosDados> buscarSelos() async {
    final dados = await _get('/api/cliente/selos');
    final proxima = dados['proxima'] as Map<String, dynamic>?;
    final sessao = dados['proximaSessao'] as Map<String, dynamic>?;

    return SelosDados(
      saldo: dados['saldo'] as int,
      sessoes: dados['sessoes'] as int? ?? 0,
      resgates: dados['resgates'] as int? ?? 0,
      clienteDesde: DateTime.tryParse(dados['desde'] as String? ?? ''),
      proxima: proxima == null
          ? null
          : ProximaRecompensa(
              nome: proxima['nome'] as String,
              selos: proxima['selos'] as int,
            ),
      proximaSessao: sessao == null
          ? null
          : ProximaSessao(
              inicio: DateTime.parse(sessao['inicio'] as String),
              servico: limparNomeServico(sessao['servico'] as String? ?? 'Sessão'),
              unidade: sessao['unidade'] == null
                  ? null
                  : corrigirAcentos(sessao['unidade'] as String),
            ),
      historico: [
        for (final item in dados['historico'] as List)
          SeloGanho(
            data: DateTime.parse((item as Map<String, dynamic>)['data'] as String),
            servico: limparNomeServico(item['servico'] as String? ?? 'Atendimento'),
          ),
      ],
    );
  }


  Future<RecompensasDados> buscarRecompensas() async {
    final dados = await _get('/api/cliente/recompensas');

    return RecompensasDados(
      saldo: dados['saldo'] as int,
      recompensas: [
        for (final item in dados['recompensas'] as List)
          Recompensa(
            id: (item as Map<String, dynamic>)['id'] as int,
            nome: item['nome'] as String,
            descricao: item['descricao'] as String?,
            selos: item['selos'] as int,
          ),
      ],
      resgates: [
        for (final item in dados['resgates'] as List)
          Resgate(
            codigo: (item as Map<String, dynamic>)['codigo'] as String,
            nome: item['nome'] as String,
            selos: item['selos'] as int,
            data: DateTime.parse(item['data'] as String),
            usado: item['usado'] as bool,
          ),
      ],
    );
  }

  /// Resgata a recompensa e devolve o código para usar na recepção.
  Future<String> resgatar(int recompensaId) async {
    final http.Response resposta;
    try {
      resposta = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/cliente/resgatar'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'cliente': _idDoCliente(),
              'recompensa': recompensaId,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const ClienteException('Não foi possível conectar ao servidor.');
    }

    final dados = _lerJson(resposta);
    if (resposta.statusCode != 201) {
      throw ClienteException(
        dados['erro'] as String? ?? 'Não foi possível resgatar.',
      );
    }
    return dados['codigo'] as String;
  }

  Future<Map<String, dynamic>> _get(String caminho) async {
    final http.Response resposta;
    try {
      resposta = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}$caminho')
                .replace(queryParameters: {'cliente': _idDoCliente()}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const ClienteException('Não foi possível conectar ao servidor.');
    }

    final dados = _lerJson(resposta);
    if (resposta.statusCode != 200) {
      throw ClienteException(
        dados['erro'] as String? ?? 'Erro ao carregar os dados.',
      );
    }
    return dados;
  }

  String _idDoCliente() {
    final usuario = Sessao.usuario;
    if (usuario == null || !usuario.ehCliente) {
      throw const ClienteException('Sessão expirada. Faça login novamente.');
    }
    return usuario.id;
  }

  Map<String, dynamic> _lerJson(http.Response resposta) {
    try {
      return jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
