class Atendimento {
  final String cliente;
  final DateTime inicio;
  final DateTime fim;
  final double? valor;

  Atendimento({
    required this.cliente,
    required this.inicio,
    required this.fim,
    required this.valor,
  });

  factory Atendimento.fromJson(Map<String, dynamic> json) {
    return Atendimento(
      cliente: json['cliente'] as String,
      inicio: DateTime.parse(json['inicio'] as String),
      fim: DateTime.parse(json['fim'] as String),
      valor: (json['valor'] as num?)?.toDouble(),
    );
  }
}
