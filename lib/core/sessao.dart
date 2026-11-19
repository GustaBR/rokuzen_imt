
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/usuario.dart';

/// Gerencia a sessão do usuário e mantém seus dados salvos
/// mesmo quando o aplicativo é atualizado ou fechado.
class Sessao {
  Sessao._();

  static Usuario? usuario;
  static Unidade? unidade;

  static const String _chaveSessao = 'rokuzen_sessao';

  /// Inicia a sessão e salva os dados localmente.
  static Future<void> iniciar(Usuario novoUsuario) async {
    usuario = novoUsuario;

    // TODO: se o usuário tiver mais de uma unidade,
    // perguntar qual usar.
    unidade = novoUsuario.unidades.isEmpty
        ? null
        : novoUsuario.unidades.first;

    final preferencias = await SharedPreferences.getInstance();

    final dados = {
      'usuario': {
        'id': novoUsuario.id,
        'nome': novoUsuario.nome,
        'tipo': novoUsuario.tipo,
        'perfil': novoUsuario.perfil,
        'unidades': novoUsuario.unidades.map((u) {
          return {
            'id': u.id,
            'nome': u.nome,
          };
        }).toList(),
      },
      'unidadeSelecionada': unidade?.id,
    };

    await preferencias.setString(
      _chaveSessao,
      jsonEncode(dados),
    );
  }

  /// Recupera a sessão salva anteriormente.
  static Future<void> restaurar() async {
    final preferencias = await SharedPreferences.getInstance();

    final dadosSalvos = preferencias.getString(_chaveSessao);

    if (dadosSalvos == null) return;

    try {
      final dados = jsonDecode(dadosSalvos) as Map<String, dynamic>;

      final dadosUsuario = dados['usuario'] as Map<String, dynamic>;

      usuario = Usuario.fromJson(dadosUsuario);

      final unidadeId = dados['unidadeSelecionada'] as String?;

      if (unidadeId != null) {
        for (final item in usuario!.unidades) {
          if (item.id == unidadeId) {
            unidade = item;
            break;
          }
        }
      }

      unidade ??= usuario!.unidades.isEmpty
          ? null
          : usuario!.unidades.first;
    } catch (e) {
      // Se os dados salvos estiverem inválidos,
      // remove a sessão para evitar erros na inicialização.
      await preferencias.remove(_chaveSessao);
      usuario = null;
      unidade = null;
    }
  }

  /// Encerra a sessão e remove os dados salvos.
  static Future<void> encerrar() async {
    usuario = null;
    unidade = null;

    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_chaveSessao);
  }
}
