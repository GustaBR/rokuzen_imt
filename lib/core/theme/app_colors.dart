import 'package:flutter/material.dart';

/// Paleta oficial do projeto, baseada no Manual de Marca da Rokuzen.
/// Use SEMPRE essas cores nas telas, nunca escreva Color(0xFF...) direto.
///
/// Precisa de uma cor nova? Adicione aqui (em PR separado)
/// e avise o grupo.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------
  // Cores principais (manual da marca)
  // ---------------------------------------------------------------
  static const Color verde = Color(0xFF9AB946);
  static const Color preto = Color(0xFF000000);
  static const Color branco = Color(0xFFFFFFFF);
  static const Color roxo = Color(0xFF500596);

  // ---------------------------------------------------------------
  // Cores de apoio (manual da marca)
  // ---------------------------------------------------------------
  static const Color rosa = Color(0xFFFF66C4);
  static const Color creme = Color(0xFFFCFBF2);
  static const Color marrom = Color(0xFF694300);

  // ---------------------------------------------------------------
  // Variações do verde (calculadas a partir do verde oficial)
  // ---------------------------------------------------------------
  static const Color verdeMuitoEscuro = Color(0xFF5C6F2A);
  static const Color verdeEscuro = Color(0xFF7B9438); // hover / pressionado
  static const Color verdeClaro = Color(0xFFCDDCA2);
  static const Color verdeFundo = Color(0xFFEBF1DA); // menu e barra superior

  // ---------------------------------------------------------------
  // Neutros
  // ---------------------------------------------------------------
  static const Color cinzaEscuro = Color(0xFF5E5755);
  static const Color cinza = Color(0xFF857C7A);
  static const Color cinzaClaro = Color(0xFFBDB7B5);
  static const Color cinzaMuitoClaro = Color(0xFFE5E1DF);

  // ---------------------------------------------------------------
  // Texto
  // ---------------------------------------------------------------
  static const Color textoPrincipal = preto;
  static const Color textoSecundario = cinza;
  static const Color textoDesabilitado = cinzaClaro;
  static const Color textoSobreVerde = branco;

  // ---------------------------------------------------------------
  // Fundos e superfícies
  // ---------------------------------------------------------------
  static const Color fundoConteudo = creme; // fundo das telas
  static const Color borda = Color(0xFFD7E3B5);

  // ---------------------------------------------------------------
  // Destaques
  // ---------------------------------------------------------------
  static const Color cardSessao = verdeClaro;
  static const Color cardSessaoClaro = verdeFundo;
  static const Color destaque = roxo; // dia selecionado, itens ativos

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
