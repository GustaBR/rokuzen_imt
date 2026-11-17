class Atendimento {
  final String cliente;
  final DateTime inicio;
  final DateTime fim;
  final double valor;

  Atendimento({
    required this.cliente,
    required this.inicio,
    required this.fim,
    required this.valor,
  });

  Atendimento.fromJson(Map<String, dynamic> json)
    : cliente = json['cliente'] as String,
      inicio = DateTime.parse(json['inicio'] as String),
      fim = DateTime.parse(json['fim'] as String),
      valor = double.parse(json['valor'] as String);
}
