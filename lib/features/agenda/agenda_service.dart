import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_config.dart';
import '../../core/sessao.dart';

/// Um atendimento da agenda: da Rokuzen (tabela atd) ou particular
/// (tabela maua_atendimento_particular).
class Atendimento {
  final DateTime inicio;
  final DateTime? fim;
  final String cliente;
  final String servico;
  final String? clienteId;

  /// Preenchido só nos atendimentos particulares.
  final int? particularId;

  const Atendimento({
    required this.inicio,
    required this.fim,
    required this.cliente,
    required this.servico,
    required this.clienteId,
    this.particularId,
  });

  bool get ehParticular => particularId != null;

  factory Atendimento.fromJson(Map<String, dynamic> json) {
    return Atendimento(
      inicio: DateTime.parse(json['inicio'] as String),
      fim: json['fim'] == null ? null : DateTime.parse(json['fim'] as String),
      cliente: json['cliente'] as String? ?? 'Cliente não informado',
      servico: _limparNomeServico(json['servico'] as String? ?? ''),
      clienteId: json['clienteId'] as String?,
    );
  }

  factory Atendimento.particularFromJson(Map<String, dynamic> json) {
    return Atendimento(
      inicio: DateTime.parse(json['inicio'] as String),
      fim: DateTime.parse(json['fim'] as String),
      cliente: json['cliente'] as String? ?? 'Atendimento particular',
      servico: json['observacao'] as String? ?? 'Atendimento particular',
      clienteId: null,
      particularId: json['id'] as int,
    );
  }
}

/// Um turno de trabalho na escala (tabela events).
class Turno {
  final DateTime inicio;
  final DateTime? fim;

  const Turno({required this.inicio, required this.fim});

  factory Turno.fromJson(Map<String, dynamic> json) {
    return Turno(
      inicio: DateTime.parse(json['inicio'] as String),
      fim: json['fim'] == null ? null : DateTime.parse(json['fim'] as String),
    );
  }
}

/// Paciente encontrado na busca (para marcar atendimento Rokuzen).
class PacienteResumo {
  final String id;
  final String nome;
  final String? nascimento;
  final String? celular;

  const PacienteResumo({
    required this.id,
    required this.nome,
    required this.nascimento,
    required this.celular,
  });

  factory PacienteResumo.fromJson(Map<String, dynamic> json) {
    return PacienteResumo(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? 'Sem nome',
      nascimento: json['nascimento'] as String?,
      celular: json['celular'] as String?,
    );
  }
}

/// Serviço da unidade (tabela tpr).
class Servico {
  final String id;
  final String nome;

  const Servico({required this.id, required this.nome});

  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      id: json['id'] as String,
      nome: _limparNomeServico(json['nome'] as String? ?? ''),
    );
  }
}

class AgendaDados {
  final List<Atendimento> atendimentos;
  final List<Turno> turnos;

  const AgendaDados({required this.atendimentos, required this.turnos});
}

class AgendaException implements Exception {
  final String mensagem;

  const AgendaException(this.mensagem);
}

class AgendaService {
  /// Busca a agenda do terapeuta logado entre [inicio] e [fim] (fim não incluso).
  Future<AgendaDados> buscar(DateTime inicio, DateTime fim) async {
    final dados = await _buscarJson(
      Uri.parse('${ApiConfig.baseUrl}/api/agenda').replace(
        queryParameters: {
          'terapeuta': _idDoTerapeuta(),
          'inicio': _formatarData(inicio),
          'fim': _formatarData(fim),
        },
      ),
    ) as Map<String, dynamic>;

    // Rokuzen e particulares numa lista só, em ordem de horário
    final atendimentos = [
      for (final item in dados['sessoes'] as List)
        Atendimento.fromJson(item as Map<String, dynamic>),
      for (final item in dados['particulares'] as List)
        Atendimento.particularFromJson(item as Map<String, dynamic>),
    ]..sort((a, b) => a.inicio.compareTo(b.inicio));

    return AgendaDados(
      atendimentos: atendimentos,
      turnos: [
        for (final item in dados['escala'] as List)
          Turno.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  Future<List<PacienteResumo>> buscarPacientes(String termo) async {
    final dados = await _buscarJson(
      Uri.parse('${ApiConfig.baseUrl}/api/busca_pacientes')
          .replace(queryParameters: {'termo': termo}),
    ) as List;
    return [
      for (final item in dados)
        PacienteResumo.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Serviços da unidade escolhida no login.
  Future<List<Servico>> buscarServicos() async {
    final dados = await _buscarJson(
      Uri.parse('${ApiConfig.baseUrl}/api/servicos')
          .replace(queryParameters: {'unidade': _idDaUnidade()}),
    ) as List;
    return [
      for (final item in dados) Servico.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<List<String>> buscarDuracoes(String servicoId) async {
    final dados = await _buscarJson(
      Uri.parse('${ApiConfig.baseUrl}/api/duracoes')
          .replace(queryParameters: {'servico': servicoId}),
    ) as List;
    return [for (final item in dados) item as String];
  }

  /// Marca um atendimento da Rokuzen para o terapeuta logado.
  Future<void> criarAtendimentoRokuzen({
    required String pacienteId,
    required String servicoId,
    required String duracao,
    required DateTime inicio,
  }) async {
    final resposta = await _enviar(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/atendimentos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'terapeuta': _idDoTerapeuta(),
          'unidade': _idDaUnidade(),
          'paciente': pacienteId,
          'servico': servicoId,
          'duracao': duracao,
          'inicio': inicio.toIso8601String(),
        }),
      ),
    );
    if (resposta.statusCode != 201) {
      throw AgendaException(_mensagemDeErro(resposta));
    }
  }

  /// Registra um atendimento particular do terapeuta logado.
  Future<void> criarParticular({
    required String cliente,
    required String? observacao,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final resposta = await _enviar(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/particulares'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'terapeuta': _idDoTerapeuta(),
          'cliente': cliente,
          'observacao': observacao,
          'inicio': inicio.toIso8601String(),
          'fim': fim.toIso8601String(),
        }),
      ),
    );
    if (resposta.statusCode != 201) {
      throw AgendaException(_mensagemDeErro(resposta));
    }
  }

  /// Remove um atendimento particular do terapeuta logado.
  Future<void> removerParticular(int id) async {
    final resposta = await _enviar(
      () => http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/particulares/$id').replace(
          queryParameters: {'terapeuta': _idDoTerapeuta()},
        ),
      ),
    );
    if (resposta.statusCode != 200) {
      throw AgendaException(_mensagemDeErro(resposta));
    }
  }

  String _idDoTerapeuta() {
    final usuario = Sessao.usuario;
    if (usuario == null) {
      throw const AgendaException('Sessão expirada. Faça login novamente.');
    }
    return usuario.id;
  }

  String _idDaUnidade() {
    final unidade = Sessao.unidade;
    if (unidade == null) {
      throw const AgendaException(
        'Nenhuma unidade selecionada. Faça login novamente.',
      );
    }
    return unidade.id;
  }

  /// GET que devolve o JSON da resposta (ou lança AgendaException).
  Future<Object?> _buscarJson(Uri endereco) async {
    final resposta = await _enviar(() => http.get(endereco));
    if (resposta.statusCode != 200) {
      throw AgendaException(_mensagemDeErro(resposta));
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes));
  }

  /// Faz a chamada com tempo limite e transforma falha de rede em mensagem.
  Future<http.Response> _enviar(
    Future<http.Response> Function() chamada,
  ) async {
    try {
      return await chamada().timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const AgendaException('Não foi possível conectar ao servidor.');
    }
  }

  /// Usa a mensagem de erro que o servidor mandou, se houver.
  String _mensagemDeErro(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes))
          as Map<String, dynamic>;
      return dados['erro'] as String? ??
          'Não foi possível concluir a operação.';
    } catch (_) {
      return 'Não foi possível concluir a operação.';
    }
  }

  String _formatarData(DateTime data) =>
      '${data.year}-${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';
}

/// Os nomes dos serviços no banco têm um prefixo usado para ordenar as listas
/// (ex.: "1.Quick Massage", "D.GIFT CARD", "(2020)3.MACA"). Aqui ele é removido
/// e os acentos são corrigidos.
String _limparNomeServico(String nome) => _corrigirAcentos(nome)
    .replaceFirst(RegExp(r'^(\(\d+\))?\s*\w{1,2}\.\s*'), '');

/// Alguns textos do banco foram gravados em UTF-8 mas são lidos como latin1,
/// e "Sessão" vira "SessÃ£o". Aqui o texto é convertido de volta.
/// Se não for esse o caso, devolve o texto como está.
String _corrigirAcentos(String texto) {
  try {
    return utf8.decode(latin1.encode(texto));
  } catch (_) {
    return texto;
  }
}

