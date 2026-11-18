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
  final String perfil;

  const Usuario({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.unidades,
    required this.perfil,
  });

  bool get ehTerapeuta => tipo == '3';
  bool get ehCliente => perfil == 'cliente';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      perfil: json['perfil'] as String? ?? 'terapeuta',
      tipo: json['tipo'] as String?,
      unidades: [
        for (final unidade in json['unidades'] as List)
          Unidade.fromJson(unidade as Map<String, dynamic>),
      ],
    );
  }
}