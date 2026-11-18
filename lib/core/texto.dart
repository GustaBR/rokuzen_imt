import 'dart:convert';

/// Os nomes dos serviços no banco têm um prefixo usado para ordenar as listas
/// (ex.: "1.Quick Massage", "D.GIFT CARD", "(2020)3.MACA"). Aqui ele é removido
/// e os acentos são corrigidos.
String limparNomeServico(String nome) => corrigirAcentos(nome)
    .replaceFirst(RegExp(r'^(\(\d+\))?\s*\w{1,2}\.\s*'), '');

/// Alguns textos do banco foram gravados em UTF-8 mas são lidos como latin1,
/// e "Sessão" vira "SessÃ£o". Aqui o texto é convertido de volta.
/// Se não for esse o caso, devolve o texto como está.
String corrigirAcentos(String texto) {
  try {
    return utf8.decode(latin1.encode(texto));
  } catch (_) {
    return texto;
  }
}
