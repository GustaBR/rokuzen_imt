import 'package:flutter/material.dart';

/// Paleta oficial do projeto. Use SEMPRE essas cores nas telas,
/// nunca escreva Color(0xFF...) direto no código da tela.
///
/// Precisa de uma cor nova? Adicione aqui (em PR separado)
/// e avise o grupo.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------
  // Marca: verde
  // ---------------------------------------------------------------
  static const Color verdeMuitoEscuro = Color(0xFF4E6822);
  static const Color verdeEscuro = Color(0xFF6E9130); // hover / pressionado
  static const Color verde = Color(0xFF8FBA42); // cor principal
  static const Color verdeClaro = Color(0xFFD4E487);
  static const Color verdeFundo = Color(0xFFEBEDCB); // menu e barra superior

  // ---------------------------------------------------------------
  // Marca: marrom
  // ---------------------------------------------------------------
  static const Color marromEscuro = Color(0xFF33281F);
  static const Color marrom = Color(0xFF5C4A3D);

  // ---------------------------------------------------------------
  // Neutros
  // ---------------------------------------------------------------
  static const Color cinzaEscuro = Color(0xFF5E5755);
  static const Color cinza = Color(0xFF857C7A);
  static const Color cinzaClaro = Color(0xFFBDB7B5);
  static const Color cinzaMuitoClaro = Color(0xFFE5E1DF);
  static const Color branco = Color(0xFFFCFCFC);

  // ---------------------------------------------------------------
  // Texto
  // ---------------------------------------------------------------
  static const Color textoPrincipal = marromEscuro;
  static const Color textoSecundario = cinza;
  static const Color textoDesabilitado = cinzaClaro;
  static const Color textoSobreVerde = branco;

  // ---------------------------------------------------------------
  // Fundos e superfícies
  // ---------------------------------------------------------------
  static const Color fundoConteudo = Color(0xFFF1EDE6); // fundo bege das telas
  static const Color borda = Color(0xFFC9D98F);

  // ---------------------------------------------------------------
  // Destaques
  // ---------------------------------------------------------------
  static const Color cardSessao = Color(0xFFF7E68A); // amarelo dos cards
  static const Color cardSessaoClaro = Color(0xFFFBF3C8);
  static const Color destaque = Color(0xFFE0602A); // dia selecionado, alertas

  // ---------------------------------------------------------------
  // Estados (mensagens, validação de formulário)
  // ---------------------------------------------------------------
  static const Color sucesso = Color(0xFF5E9C3A);
  static const Color sucessoFundo = Color(0xFFE7F3DE);

  static const Color erro = Color(0xFFC0392B);
  static const Color erroFundo = Color(0xFFF8E1DE);

  static const Color aviso = Color(0xFFE0A82E);
  static const Color avisoFundo = Color(0xFFFBF0D5);

  static const Color info = Color(0xFF3A7CA5);
  static const Color infoFundo = Color(0xFFDDEBF4);
}
