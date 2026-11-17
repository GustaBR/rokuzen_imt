import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_config.dart';
import '../../core/models/usuario.dart';

/// Erro de login com uma mensagem pronta para mostrar na tela.
class AuthException implements Exception {
  final String mensagem;

  const AuthException(this.mensagem);
}

class AuthService {
  /// Faz login na API e devolve o usuário.
  /// Lança [AuthException] se o login falhar.
  Future<Usuario> login(String login, String senha) async {
    final http.Response resposta;
    try {
      resposta = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'login': login, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const AuthException(
        'Não foi possível conectar ao servidor. Tente novamente.',
      );
    }

    final Map<String, dynamic> dados;
    try {
      dados = jsonDecode(utf8.decode(resposta.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw const AuthException('Resposta inválida do servidor.');
    }

    if (resposta.statusCode != 200) {
      throw AuthException(dados['erro'] as String? ?? 'Erro ao entrar.');
    }

    return Usuario.fromJson(dados);
  }

    /// Cria a conta do cliente. Lança [AuthException] se der errado.
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String celular,
    required String cpf,
    required DateTime nascimento,
    required String senha,
  }) {
    return _enviarCadastro('/api/cadastro_cliente', {
      'nome': nome,
      'email': email,
      'celular': celular,
      'cpf': cpf,
      'nascimento': nascimento.toIso8601String().substring(0, 10),
      'senha': senha,
    });
  }

  
  Future<void> cadastrarTerapeuta({
    required String email,
    required String cpf,
    required DateTime nascimento,
    required String senha,
  }) {
    return _enviarCadastro('/api/cadastro_terapeuta', {
      'email': email,
      'cpf': cpf,
      'nascimento': nascimento.toIso8601String().substring(0, 10),
      'senha': senha,
    });
  }

  Future<void> _enviarCadastro(String caminho, Map<String, Object> dados) async {
    final http.Response resposta;
    try {
      resposta = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$caminho'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(dados),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const AuthException(
        'Não foi possível conectar ao servidor. Tente novamente.',
      );
    }

    if (resposta.statusCode == 201) return;

    var mensagem = 'Não foi possível criar a conta.';
    try {
      final corpo =
          jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
      mensagem = corpo['erro'] as String? ?? mensagem;
    } catch (_) {}
    throw AuthException(mensagem);
  }


}
