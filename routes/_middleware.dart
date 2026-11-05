import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:mysql_dart/mysql_dart.dart';
import 'package:pi_20262_imt/database/connection.dart';

Handler middleware(Handler handler) {
  var env = DotEnv(includePlatformEnvironment: true)..load();

  final pool = DatabaseConnection(
    host: env['DB_HOST']!,
    port: int.parse(env['DB_PORT']!),
    database: env['DB_NAME']!,
    user: env['DB_USER']!,
    password: env['DB_PASSWORD']!,
  ).createPool();

   return handler
      .use(provider<MySQLConnectionPool>((context) => pool))
      .use(_cors());

}

Middleware _cors() {
  return (handler) {
    return (context) async {
      if (context.request.method == HttpMethod.options) {
        return Response(headers: _cabecalhosCors);
      }
      final response = await handler(context);
      return response.copyWith(
        headers: {...response.headers, ..._cabecalhosCors},
      );
    };
  };
}

const _cabecalhosCors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};