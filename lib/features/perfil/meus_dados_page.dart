
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MeusDadosPage extends StatefulWidget {
  const MeusDadosPage({super.key});

  @override
  State<MeusDadosPage> createState() => _MeusDadosPageState();
}

class _MeusDadosPageState extends State<MeusDadosPage> {
  // Dados pessoais
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _apelidoController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _rgController = TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();

  // Endereço
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController =
      TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _unidadeController = TextEditingController();

  // Dados da conta
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _senhaAtualController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  int _abaSelecionada = 0;

  bool _mostrarSenhaAtual = false;
  bool _mostrarNovaSenha = false;
  bool _mostrarConfirmarSenha = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _apelidoController.dispose();
    _cpfController.dispose();
    _rgController.dispose();
    _dataNascimentoController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _celularController.dispose();

    _cepController.dispose();
    _estadoController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _unidadeController.dispose();

    _loginController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, pageConstraints) {
        final largura = pageConstraints.maxWidth;
        final mobile = largura < 600;
        final desktop = largura >= 850;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 12 : 18,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: AppColors.marrom,
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Meus Dados',
                    style: TextStyle(
                      color: AppColors.marrom,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                'Visualize e gerencie suas informações pessoais e sua conta.',
                style: TextStyle(
                  color: AppColors.cinza,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              if (desktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 250,
                      child: _menuPerfil(),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 520,
                        ),
                        child: _conteudoAba(mobile: false),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _menuPerfil(),
                    const SizedBox(height: 16),
                    _conteudoAba(mobile: mobile),
                  ],
                ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.marrom,
                        side: const BorderSide(color: AppColors.borda),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),

                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verde,
                        foregroundColor: AppColors.branco,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Salvar alterações'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // Menu lateral do perfil
  Widget _menuPerfil() {
    final opcoes = [
      ('Dados pessoais', Icons.person_outline),
      ('Endereço', Icons.location_on_outlined),
      ('Dados da conta', Icons.lock_outline),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.verdeFundo,
            child: const Icon(
              Icons.person_outline,
              color: AppColors.marrom,
              size: 42,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Nome do terapeuta',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.marrom,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Usuário: terapeuta',
            style: TextStyle(
              color: AppColors.cinza,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.verdeFundo,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Conta ativa',
              style: TextStyle(
                color: AppColors.marrom,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          ...List.generate(opcoes.length, (index) {
            final selecionada = _abaSelecionada == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() {
                    _abaSelecionada = index;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: selecionada
                        ? AppColors.verdeFundo
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opcoes[index].$2,
                        color: AppColors.marrom,
                        size: 19,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        opcoes[index].$1,
                        style: TextStyle(
                          color: AppColors.marrom,
                          fontSize: 13,
                          fontWeight: selecionada
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Conteúdo da aba selecionada
  Widget _conteudoAba({required bool mobile}) {
    switch (_abaSelecionada) {
      case 0:
        return _dadosPessoais(mobile: mobile);
      case 1:
        return _endereco(mobile: mobile);
      case 2:
        return _dadosConta(mobile: mobile);
      default:
        return _dadosPessoais(mobile: mobile);
    }
  }

  // Aba: Dados pessoais
  Widget _dadosPessoais({required bool mobile}) {
    return _cartaoSecao(
      titulo: 'Dados pessoais',
      icone: Icons.person_outline,
      children: [
        _gradeCampos(
          mobile: mobile,
          campos: [
            _campoDado('Nome completo', _nomeController),
            _campoDado('Apelido', _apelidoController),
            _campoDado('CPF', _cpfController),
            _campoDado('RG', _rgController),
            _campoDado('Data de nascimento', _dataNascimentoController),
            _campoDado('E-mail', _emailController),
            _campoDado('Telefone', _telefoneController),
            _campoDado('Celular', _celularController),
          ],
        ),
      ],
    );
  }

  // Aba: Endereço
  Widget _endereco({required bool mobile}) {
    return _cartaoSecao(
      titulo: 'Endereço',
      icone: Icons.location_on_outlined,
      children: [
        _gradeCampos(
          mobile: mobile,
          campos: [
            _campoDado('CEP', _cepController),
            _campoDado('Estado (UF)', _estadoController),
            _campoDado('Rua', _ruaController),
            _campoDado('Número', _numeroController),
            _campoDado('Complemento', _complementoController),
            _campoDado('Bairro', _bairroController),
            _campoDado('Cidade', _cidadeController),
            _campoDado('Unidade', _unidadeController),
          ],
        ),
      ],
    );
  }

  // Aba: Dados da conta
  Widget _dadosConta({required bool mobile}) {
    return _cartaoSecao(
      titulo: 'Dados da conta',
      icone: Icons.lock_outline,
      children: [
        const Text(
          'Gerencie suas informações de acesso e altere sua senha.',
          style: TextStyle(
            color: AppColors.cinza,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 24),

        _gradeCampos(
          mobile: mobile,
          campos: [
            _campoDado('Nome de usuário / Login', _loginController),
            _campoDado('E-mail da conta', _emailController),
          ],
        ),

        const SizedBox(height: 28),

        const Text(
          'Alteração de senha',
          style: TextStyle(
            color: AppColors.marrom,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        _gradeCampos(
          mobile: mobile,
          campos: [
            _campoSenha(
              'Senha atual',
              _senhaAtualController,
              _mostrarSenhaAtual,
              () {
                setState(() {
                  _mostrarSenhaAtual = !_mostrarSenhaAtual;
                });
              },
            ),
            _campoSenha(
              'Nova senha',
              _novaSenhaController,
              _mostrarNovaSenha,
              () {
                setState(() {
                  _mostrarNovaSenha = !_mostrarNovaSenha;
                });
              },
            ),
            _campoSenha(
              'Confirmar nova senha',
              _confirmarSenhaController,
              _mostrarConfirmarSenha,
              () {
                setState(() {
                  _mostrarConfirmarSenha = !_mostrarConfirmarSenha;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  // Distribuição responsiva dos campos
  Widget _gradeCampos({
    required bool mobile,
    required List<Widget> campos,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;

        final int colunas;

        if (mobile || largura < 550) {
          colunas = 1;
        } else {
          colunas = 2;
        }

        const espacamentoHorizontal = 24.0;
        const espacamentoVertical = 28.0;

        final larguraCampo = (largura -
                espacamentoHorizontal * (colunas - 1)) /
            colunas;

        return Wrap(
          spacing: espacamentoHorizontal,
          runSpacing: espacamentoVertical,
          children: campos.map((campo) {
            return SizedBox(
              width: larguraCampo,
              child: campo,
            );
          }).toList(),
        );
      },
    );
  }

  // Campo individual
  Widget _campoDado(
    String titulo,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: AppColors.marrom,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.branco,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 17,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.borda,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.borda,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.verde,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Campo de senha com opção de visualizar
  Widget _campoSenha(
    String titulo,
    TextEditingController controller,
    bool mostrarSenha,
    VoidCallback alternarVisibilidade,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: AppColors.marrom,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          controller: controller,
          obscureText: !mostrarSenha,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.branco,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 17,
            ),
            isDense: true,
            suffixIcon: IconButton(
              onPressed: alternarVisibilidade,
              icon: Icon(
                mostrarSenha
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 19,
                color: AppColors.cinza,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.borda,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.borda,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.verde,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Cartão das seções
  Widget _cartaoSecao({
    required String titulo,
    required IconData icone,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 520,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borda,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icone,
                color: AppColors.marrom,
                size: 23,
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  color: AppColors.marrom,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          ...children,
        ],
      ),
    );
  }
}
