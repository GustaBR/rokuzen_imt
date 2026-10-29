import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/auth_layout.dart';
import '../home/home_page.dart';
import 'widgets/campo_rotulado.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _ocultarSenha = true;

  @override 
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _entrar() {
    if (!_formKey.currentState!.validate()) return;

    // chamar api de login, o back-end responde se é colaborador ou terapeuta
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      formulario: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bem-Vindo!',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 36,
                color: AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 32),
            CampoRotulado(
              rotulo: 'Email',
              controller: _emailController,
              tipoTeclado: TextInputType.emailAddress,
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Informe o email';
                }
                if (!valor.contains('@')) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            CampoRotulado(
              rotulo: 'Senha',
              controller: _senhaController,
              ocultarTexto: _ocultarSenha,
              iconeFinal: IconButton(
                icon: Icon(
                  _ocultarSenha
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() => _ocultarSenha = !_ocultarSenha);
                },
              ),
              validador: (valor) {
                if (valor == null || valor.isEmpty) {
                  return 'Informe a senha';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {}, // abrir tela de recuperar senha
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textoPrincipal,
                ),
                child: const Text(
                  'Esqueceu sua senha?',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _entrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.fundoConteudo,
                  foregroundColor: AppColors.textoPrincipal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Entrar', style: TextStyle(fontSize:22)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}