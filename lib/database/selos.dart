import 'package:mysql_dart/mysql_dart.dart';

/// Saldo de selos do cliente: 1 selo por atendimento já realizado (atd),
/// menos os selos gastos em resgates (maua_resgate).
Future<int> saldoDeSelos(MySQLConnectionPool pool, String cliente) async {
  final resultado = await pool.execute(
    '''
    SELECT
      CAST((SELECT COUNT(*) FROM atd
            WHERE cli_ukey = :cliente AND atd_002_c < NOW()) AS SIGNED)
      -
      CAST((SELECT COALESCE(SUM(selos), 0) FROM maua_resgate
            WHERE cli_ukey = :cliente) AS SIGNED)
      AS saldo
    ''',
    {'cliente': cliente},
  );
  return resultado.rows.first.typedColByName<int>('saldo') ?? 0;
}
