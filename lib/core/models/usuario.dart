class Unidade {
  final String id;
  final String nome;

  const Unidade({required this.id, required this.nome});

  factory Unidade.fromJson(Map<String, dynamic> json) {
    return Unidade(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
    );
  }
}

class Usuario {
  final String id;
  final String nome;
  final String? tipo;
  final List<Unidade> unidades;

  const Usuario({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.unidades,
  });

  bool get ehTerapeuta => tipo == '3';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      tipo: json['tipo'] as String?,
      unidades: [
        for (final unidade in json['unidades'] as List)
          Unidade.fromJson(unidade as Map<String, dynamic>),
      ],
    );
  }
}