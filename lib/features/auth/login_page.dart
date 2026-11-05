import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/sessao.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/auth_layout.dart';
import 'auth_service.dart';
import 'widgets/campo_rotulado.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  final _authService = AuthService();
  bool _ocultarSenha = true;
  bool _carregando = false;
  String? _mensagemErro;

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    try {
      final usuario = await _authService.login(
        _usuarioController.text.trim(),
        _senhaController.text,
      );
      Sessao.iniciar(usuario);
      if (!mounted) return;
      context.go('/');
    } on AuthException catch (e) {
      setState(() => _mensagemErro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
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
              rotulo: 'Usuário',
              controller: _usuarioController,
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Informe o usuário';
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
            if (_mensagemErro != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.erroFundo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _mensagemErro!,
                  style: const TextStyle(color: AppColors.erro),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _carregando ? null : _entrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdeFundo,
                  foregroundColor: AppColors.textoPrincipal,
                  disabledBackgroundColor: AppColors.verdeFundo,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _carregando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Entrar', style: TextStyle(fontSize: 22)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
