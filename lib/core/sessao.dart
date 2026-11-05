import 'models/usuario.dart';

/// Guarda o usuário logado e a unidade em uso enquanto o app está aberto.
class Sessao {
  Sessao._();

  static Usuario? usuario;
  static Unidade? unidade;

  static void iniciar(Usuario novoUsuario) {
    usuario = novoUsuario;
    // TODO: se o usuário tiver mais de uma unidade, perguntar qual usar
    unidade = novoUsuario.unidades.isEmpty ? null : novoUsuario.unidades.first;
  }

  static void encerrar() {
    usuario = null;
    unidade = null;
  }
}
