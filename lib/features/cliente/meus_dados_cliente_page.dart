import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/theme/app_colors.dart';
import 'cliente_service.dart';

class MeusDadosClientePage extends StatefulWidget {
  const MeusDadosClientePage({super.key});

  @override
  State<MeusDadosClientePage> createState() => _MeusDadosClientePageState();
}

class _MeusDadosClientePageState extends State<MeusDadosClientePage> {
  final ClienteService _service = ClienteService();

  MeusDadosCliente? _dados;

  Uint8List? _imagemPerfil;

  bool _carregando = true;

  String? _erro;

  int _abaSelecionada = 0;

  // Dados pessoais
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _generoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailContatoController = TextEditingController();

  // Endereço
  final _cepController = TextEditingController();
  final _estadoController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();

  // Dados da conta
  final _emailContaController = TextEditingController();

  // Alteração de senha
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _mostrarSenhaAtual = false;
  bool _mostrarNovaSenha = false;
  bool _mostrarConfirmarSenha = false;

  // Máscaras
  final _mascaraCpf = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _mascaraNascimento = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _mascaraCep = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final List<String> _estados = const [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // Carregamento dos dados do cliente

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dados = await _service.buscarMeusDados();

      if (!mounted) return;

      _dados = dados;
      _preencherCampos(dados);

      setState(() {
        _carregando = false;
      });
    } on ClienteException catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados do cliente: $e');

      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar seus dados.';
        _carregando = false;
      });
    }
  }

  void _preencherCampos(MeusDadosCliente dados) {
    final pessoal = dados.dadosPessoais;
    final endereco = dados.endereco;

    _nomeController.text = pessoal.nome ?? '';
    _cpfController.text = _mascaraCpf.maskText(pessoal.cpf ?? '');
    _nascimentoController.text = _formatarNascimento(pessoal.nascimento ?? '');
    _generoController.text = pessoal.genero ?? '';
    _telefoneController.text = _mascaraTelefone.maskText(
      pessoal.telefone ?? '',
    );
    _emailContatoController.text = pessoal.emailContato ?? '';

    _cepController.text = _mascaraCep.maskText(endereco.cep ?? '');
    _estadoController.text = endereco.uf ?? '';
    _ruaController.text = endereco.rua ?? '';
    _numeroController.text = endereco.numero ?? '';
    _complementoController.text = endereco.complemento ?? '';
    _bairroController.text = endereco.bairro ?? '';
    _cidadeController.text = endereco.cidade ?? '';

    _emailContaController.text = dados.dadosConta.email ?? '';
  }

  String _formatarNascimento(String valor) {
    if (valor.isEmpty) return '';

    final partes = valor.split('-');

    if (partes.length == 3 && partes[0].length == 4) {
      return '${partes[2]}/${partes[1]}/${partes[0]}';
    }

    return valor;
  }

// pop-up de confirmação está mockado por enquanto, não está salvando alterações, mas exibe a tela de confirmação
  void _confirmarSalvamentoMockado() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.branco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.verdeFundo,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.verde,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Alterações salvas!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.marrom,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Suas informações foram atualizadas com sucesso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.cinza, fontSize: 14),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 120,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verde,
                      foregroundColor: AppColors.branco,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Entendi',
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Mock da tela de salvamento

  void _salvarDados() {
    _confirmarSalvamentoMockado();
  }

// BUsca de CEP e preenchimento automático dos campos de endereço
  Future<void> _buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'\D'), '');

    if (cepLimpo.length != 8) return;

    try {
      final uri = Uri.https('viacep.com.br', '/ws/$cepLimpo/json/');

      final resposta = await http.get(uri);

      if (resposta.statusCode != 200) return;

      final resultado = jsonDecode(resposta.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (resultado['erro'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('CEP não encontrado.')));
        return;
      }

      setState(() {
        _ruaController.text = resultado['logradouro'] ?? '';
        _bairroController.text = resultado['bairro'] ?? '';
        _cidadeController.text = resultado['localidade'] ?? '';
        _estadoController.text = resultado['uf'] ?? '';
      });
    } catch (e) {
      debugPrint('Erro ao consultar CEP: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível consultar o CEP.')),
      );
    }
  }

// Foto de perfil
  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();

    final imagem = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (imagem == null) return;

    final bytes = await imagem.readAsBytes();

    if (!mounted) return;

    setState(() {
      _imagemPerfil = bytes;
    });
  }

  void _removerFoto() {
    setState(() {
      _imagemPerfil = null;
    });
  }

// Sistema de navegação entre abas
  void _avancarAba() {
    if (_abaSelecionada < 2) {
      setState(() {
        _abaSelecionada++;
      });
    }
  }

  void _voltarAba() {
    if (_abaSelecionada > 0) {
      setState(() {
        _abaSelecionada--;
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _nascimentoController.dispose();
    _generoController.dispose();
    _telefoneController.dispose();
    _emailContatoController.dispose();

    _cepController.dispose();
    _estadoController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();

    _emailContaController.dispose();

    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;
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
                style: TextStyle(color: AppColors.cinza, fontSize: 14),
              ),

              const SizedBox(height: 20),

              if (_carregando)
                const Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.verde),
                  ),
                )
              else if (_erro != null)
                _mensagemErro()
              else if (_dados != null)
                if (desktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 250, child: _menuPerfil()),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 520),
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

              if (!_carregando && _dados != null) ...[
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (_abaSelecionada > 0)
                        OutlinedButton.icon(
                          onPressed: _voltarAba,
                          icon: const Icon(Icons.arrow_back, size: 17),
                          label: const Text('Voltar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.marrom,
                            side: const BorderSide(color: AppColors.borda),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),

                      if (_abaSelecionada < 2)
                        ElevatedButton.icon(
                          onPressed: _avancarAba,
                          icon: const Icon(Icons.arrow_forward, size: 17),
                          label: const Text('Próximo'),
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
                        ),

                      if (_abaSelecionada == 2)
                        ElevatedButton.icon(
                          onPressed: _salvarDados,
                          icon: const Icon(Icons.check, size: 17),
                          label: const Text('Salvar alterações'),
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
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

// Tratamento de erros e exibição de mensagens de erro
  Widget _mensagemErro() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.erro, size: 42),
          const SizedBox(height: 12),
          Text(
            _erro!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.cinza),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _carregarDados,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verde,
              foregroundColor: AppColors.branco,
            ),
          ),
        ],
      ),
    );
  }

// Menu lateral para mobile
  Widget _menuPerfil() {
    final opcoes = [
      ('Dados pessoais', Icons.person_outline),
      ('Endereço', Icons.location_on_outlined),
      ('Dados da conta', Icons.lock_outline),
    ];

    final nome = _dados?.dadosPessoais.nome;

    final nomeExibido = nome == null || nome.trim().isEmpty
        ? 'Cliente Rokuzen'
        : nome;

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
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: Container(
                  width: 112,
                  height: 112,
                  color: AppColors.verdeFundo,
                  child: _imagemPerfil != null
                      ? Image.memory(
                          _imagemPerfil!,
                          width: 112,
                          height: 112,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.person_outline,
                          color: AppColors.marrom,
                          size: 68,
                        ),
                ),
              ),

              if (_imagemPerfil != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Material(
                    color: AppColors.erro,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _removerFoto,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.close, color: Colors.white, size: 15),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: 130,
            height: 34,
            child: FilledButton.icon(
              onPressed: _selecionarFoto,
              icon: const Icon(Icons.photo_camera_outlined, size: 16),
              label: const Text(
                'Adicionar foto',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.verdeFundo,
                foregroundColor: AppColors.marrom,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(130, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Selecione uma imagem',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.cinza, fontSize: 10),
          ),

          const SizedBox(height: 12),

          Text(
            nomeExibido,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.marrom,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Usuário: cliente',
            style: TextStyle(color: AppColors.cinza, fontSize: 12),
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
                      Icon(opcoes[index].$2, color: AppColors.marrom, size: 19),
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

// Dados pesoais, endereço e dados da conta
  Widget _dadosPessoais({required bool mobile}) {
    return _cartaoSecao(
      titulo: 'Dados pessoais',
      icone: Icons.person_outline,
      children: [
        _gradeCampos(
          mobile: mobile,
          campos: [
            _campoDado('Nome completo', _nomeController),
            _campoDado('CPF', _cpfController, inputFormatters: [_mascaraCpf]),
            _campoDado(
              'Data de nascimento',
              _nascimentoController,
              inputFormatters: [_mascaraNascimento],
              hintText: 'DD/MM/AAAA',
            ),
            _campoGenero(),
            _campoDado(
              'Telefone / Celular',
              _telefoneController,
              inputFormatters: [_mascaraTelefone],
            ),
            _campoDado('E-mail de contato', _emailContatoController),
          ],
        ),
      ],
    );
  }

  Widget _endereco({required bool mobile}) {
    return _cartaoSecao(
      titulo: 'Endereço',
      icone: Icons.location_on_outlined,
      children: [
        _gradeCampos(
          mobile: mobile,
          campos: [
            _campoDado(
              'CEP',
              _cepController,
              inputFormatters: [_mascaraCep],
              onChanged: _buscarCep,
            ),
            _campoEstado(),
            _campoDado('Rua', _ruaController),
            _campoDado('Número', _numeroController),
            _campoDado('Complemento', _complementoController),
            _campoDado('Bairro', _bairroController),
            _campoDado('Cidade', _cidadeController),
          ],
        ),
      ],
    );
  }

  Widget _dadosConta({required bool mobile}) {
    return _cartaoSecao(
      titulo: 'Dados da conta',
      icone: Icons.lock_outline,
      children: [
        const Text(
          'Informações utilizadas para acessar sua conta Rokuzen.',
          style: TextStyle(color: AppColors.cinza, fontSize: 13),
        ),

        const SizedBox(height: 24),

        _gradeCampos(
          mobile: mobile,
          campos: [
            _campoDado(
              'E-mail da conta',
              _emailContaController,
              readOnly: true,
            ),
          ],
        ),

        const SizedBox(height: 28),

        const Divider(color: AppColors.borda),

        const SizedBox(height: 20),

        const Text(
          'Alterar senha',
          style: TextStyle(
            color: AppColors.marrom,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Para alterar sua senha, informe a senha atual e escolha uma nova.',
          style: TextStyle(color: AppColors.cinza, fontSize: 13),
        ),

        const SizedBox(height: 24),

        _gradeCampos(
          mobile: mobile,
          campos: [
            _campoSenha(
              'Senha atual',
              _senhaAtualController,
              mostrarSenha: _mostrarSenhaAtual,
              alternarVisibilidade: () {
                setState(() {
                  _mostrarSenhaAtual = !_mostrarSenhaAtual;
                });
              },
            ),
            _campoSenha(
              'Nova senha',
              _novaSenhaController,
              mostrarSenha: _mostrarNovaSenha,
              alternarVisibilidade: () {
                setState(() {
                  _mostrarNovaSenha = !_mostrarNovaSenha;
                });
              },
            ),
            _campoSenha(
              'Confirmar nova senha',
              _confirmarSenhaController,
              mostrarSenha: _mostrarConfirmarSenha,
              alternarVisibilidade: () {
                setState(() {
                  _mostrarConfirmarSenha = !_mostrarConfirmarSenha;
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppColors.cinza, size: 19),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'A nova senha deve possuir pelo menos 8 caracteres. '
                'Deixe os campos vazios caso não queira alterá-la.',
                style: TextStyle(color: AppColors.cinza, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _campoGenero() {
    final valor = _generoController.text.toUpperCase();

    final generoSelecionado = switch (valor) {
      'F' || 'FEMININO' => 'F',
      'M' || 'MASCULINO' => 'M',
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gênero',
          style: TextStyle(
            color: AppColors.marrom,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          initialValue: generoSelecionado,
          isExpanded: true,
          decoration: _decoracaoCampo(),
          hint: const Text('Selecione'),
          items: const [
            DropdownMenuItem(value: 'F', child: Text('Feminino')),
            DropdownMenuItem(value: 'M', child: Text('Masculino')),
          ],
          onChanged: (valor) {
            if (valor == null) return;

            setState(() {
              _generoController.text = valor;
            });
          },
        ),
      ],
    );
  }

  Widget _campoEstado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado (UF)',
          style: TextStyle(
            color: AppColors.marrom,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          initialValue: _estados.contains(_estadoController.text)
              ? _estadoController.text
              : null,
          isExpanded: true,
          decoration: _decoracaoCampo(),
          hint: const Text('Selecione'),
          items: _estados.map((estado) {
            return DropdownMenuItem(value: estado, child: Text(estado));
          }).toList(),
          onChanged: (estado) {
            if (estado == null) return;

            setState(() {
              _estadoController.text = estado;
            });
          },
        ),
      ],
    );
  }

  Widget _gradeCampos({required bool mobile, required List<Widget> campos}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;
        final colunas = mobile || largura < 550 ? 1 : 2;

        const espacamentoHorizontal = 24.0;
        const espacamentoVertical = 28.0;

        final larguraCampo =
            (largura - espacamentoHorizontal * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espacamentoHorizontal,
          runSpacing: espacamentoVertical,
          children: campos.map((campo) {
            return SizedBox(width: larguraCampo, child: campo);
          }).toList(),
        );
      },
    );
  }

  Widget _campoDado(
    String titulo,
    TextEditingController controller, {
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    String? hintText,
    bool readOnly = false,
  }) {
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
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          decoration: _decoracaoCampo(hintText: hintText),
        ),
      ],
    );
  }


// Alteração de senha (por enquanto mockado)
  Widget _campoSenha(
    String titulo,
    TextEditingController controller, {
    required bool mostrarSenha,
    required VoidCallback alternarVisibilidade,
  }) {
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
          enableSuggestions: false,
          autocorrect: false,
          decoration: _decoracaoCampo().copyWith(
            hintText: titulo,
            suffixIcon: IconButton(
              onPressed: alternarVisibilidade,
              icon: Icon(
                mostrarSenha
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.cinza,
              ),
            ),
          ),
        ),
      ],
    );
  }
  InputDecoration _decoracaoCampo({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: AppColors.branco,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.verde, width: 1.5),
      ),
    );
  }
  
  Widget _cartaoSecao({
    required String titulo,
    required IconData icone,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 520),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: AppColors.marrom, size: 23),
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
