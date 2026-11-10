/// Funções de data usadas pela agenda.

const diasDaSemanaCurtos = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

const _diasDaSemana = [
  'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira',
  'Sexta-feira', 'Sábado', 'Domingo',
];

const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

/// A data sem a hora (meia-noite).
DateTime soData(DateTime data) => DateTime(data.year, data.month, data.day);

/// A segunda-feira da semana de [data].
DateTime inicioDaSemana(DateTime data) =>
    soData(data).subtract(Duration(days: data.weekday - 1));

bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Ex.: 09:30
String hora(DateTime data) =>
    '${data.hour.toString().padLeft(2, '0')}:'
    '${data.minute.toString().padLeft(2, '0')}';

/// Ex.: Quarta-feira, 21 de outubro
String diaPorExtenso(DateTime data) =>
    '${_diasDaSemana[data.weekday - 1]}, ${data.day} de ${_meses[data.month - 1]}';

/// Ex.: 19 – 25 de outubro de 2026  ou  29 de setembro – 5 de outubro de 2026
String periodoDaSemana(DateTime inicio) {
  final fim = inicio.add(const Duration(days: 6));
  final mesFim = '${_meses[fim.month - 1]} de ${fim.year}';
  if (inicio.month == fim.month) {
    return '${inicio.day} – ${fim.day} de $mesFim';
  }
  return '${inicio.day} de ${_meses[inicio.month - 1]} – ${fim.day} de $mesFim';
}
