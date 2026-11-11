class Atendimento {
  final String id;
  final DateTime inicio;
  final DateTime fim;
  
  Atendimento({
    required this.id,
    required this.inicio,
    required this.fim
  });

  Atendimento.fromJson(Map<String, dynamic> json) :
    id = json['id'] as String,
    inicio = DateTime.parse(json['inicio'] as String),
    fim = DateTime.parse(json['fim'] as String);
}