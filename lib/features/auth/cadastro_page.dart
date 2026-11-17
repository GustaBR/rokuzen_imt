import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/auth_layout.dart';
import 'auth_service.dart';
import 'widgets/campo_rotulado.dart';

enum _TipoConta { cliente, terapeuta }

/// Cadastro de conta do app, para clientes e terapeutas.
class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  final _cpfController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _authService = AuthService();

  final _mascaraCpf = MaskTextInputFormatter(mask: '###.###.###-##');
  final _mascaraCelular = MaskTextInputFormatter(mask: '(##) #####-####');
  final _mascaraData = MaskTextInputFormatter(mask: '##/##/####');

  _TipoConta _tipo = _TipoConta.cliente;
  bool _ocultarSenha = true;
  bool _carregando = false;
  String? _mensagemErro;

  bool get _terapeuta => _tipo == _TipoConta.terapeuta;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    _cpfController.dispose();
    _nascimentoController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  /// "20/05/2001" → DateTime, ou null se a data for inválida.
  DateTime? _lerData(String texto) {
    final partes = texto.split('/');
    if (partes.length != 3) return null;
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return null;
    final data = DateTime(ano, mes, dia);
    // DateTime aceita 31/02 e "corrige" para março; aqui isso é inválido
    if (data.day != dia || data.month != mes || data.year < 1900) return null;
    if (data.isAfter(DateTime.now())) return null;
    return data;
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    try {
      final nascimento = _lerData(_nascimentoController.text)!;
      if (_terapeuta) {
        await _authService.cadastrarTerapeuta(
          email: _emailController.text.trim(),
          cpf: _mascaraCpf.getUnmaskedText(),
          nascimento: nascimento,
          senha: _senhaController.text,
        );
      } else {
        await _authService.cadastrar(
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          celular: _celularController.text.trim(),
          cpf: _mascaraCpf.getUnmaskedText(),
          nascimento: nascimento,
          senha: _senhaController.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada! Faça login para entrar.')),
      );
      context.go('/login');
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
              'Criar conta',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 32,
                    color: AppColors.textoPrincipal,
                  ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<_TipoConta>(
              segments: const [
                ButtonSegment(value: _TipoConta.cliente, label: Text('Sou cliente')),
                ButtonSegment(
                  value: _TipoConta.terapeuta,
                  label: Text('Sou terapeuta'),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (selecao) => setState(() {
                _tipo = selecao.first;
                _mensagemErro = null;
              }),
            ),
            const SizedBox(height: 12),
            Text(
              _terapeuta
                  ? 'Use o CPF e a data de nascimento do seu cadastro na Rokuzen.'
                  : 'Acumule selos a cada sessão e troque por recompensas.',
              style: const TextStyle(color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 24),
            // Nome e celular só para clientes: o terapeuta já tem esses
            // dados no cadastro da Rokuzen
            if (!_terapeuta) ...[
              CampoRotulado(
                rotulo: 'Nome completo',
                controller: _nomeController,
                validador: (valor) => (valor == null || valor.trim().isEmpty)
                    ? 'Informe seu nome'
                    : null,
              ),
              const SizedBox(height: 16),
            ],
            CampoRotulado(
              rotulo: 'E-mail',
              controller: _emailController,
              tipoTeclado: TextInputType.emailAddress,
              validador: (valor) => (valor == null || !valor.contains('@'))
                  ? 'Informe um e-mail válido'
                  : null,
            ),
            const SizedBox(height: 16),
            if (!_terapeuta) ...[
              CampoRotulado(
                rotulo: 'Celular',
                controller: _celularController,
                tipoTeclado: TextInputType.phone,
                formatadores: [_mascaraCelular],
                validador: (_) => _mascaraCelular.getUnmaskedText().length < 10
                    ? 'Informe o celular com DDD'
                    : null,
              ),
              const SizedBox(height: 16),
            ],
            CampoRotulado(
              rotulo: 'CPF',
              controller: _cpfController,
              tipoTeclado: TextInputType.number,
              formatadores: [_mascaraCpf],
              validador: (_) => _mascaraCpf.getUnmaskedText().length != 11
                  ? 'Informe o CPF completo'
                  : null,
            ),
            const SizedBox(height: 16),
            CampoRotulado(
              rotulo: 'Data de nascimento',
              controller: _nascimentoController,
              tipoTeclado: TextInputType.number,
              formatadores: [_mascaraData],
              validador: (valor) => _lerData(valor ?? '') == null
                  ? 'Informe uma data válida (dd/mm/aaaa)'
                  : null,
            ),
            const SizedBox(height: 16),
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
                onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
              ),
              validador: (valor) => (valor == null || valor.length < 6)
                  ? 'Mínimo de 6 caracteres'
                  : null,
            ),
            if (_mensagemErro != null) ...[
              const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _carregando ? null : _cadastrar,
                child: _carregando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Criar conta', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Já tem conta? Entrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
