import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/api_config.dart';
import '../../core/sessao.dart';

class MeusDadosPage extends StatefulWidget {
  const MeusDadosPage({super.key});

  @override
  State<MeusDadosPage> createState() => _MeusDadosPageState();
}

class _MeusDadosPageState extends State<MeusDadosPage> {

  // Foto e nome do perfil
  Uint8List? _imagemPerfil;
  String _nomeTerapeuta = 'Nome do terapeuta';


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

  // Aba selecionada
  int _abaSelecionada = 0;

  // Estados disponíveis, priorizando SP como UF
  final List<String> _estados = [
    'SP', 'AC', 'AL', 'AP', 'AM', 'BA', 'CE',
    'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG',
    'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SE', 'TO',
  ];

  // Unidades cadastradas do Rokuzen
  final List<String> _unidades = [
    'Grand Plaza Shopping - Loja 305 (Santo André)',
    'Golden Square Shopping - Piso 1 (São Bernardo do Campo)',
    'Mooca Plaza Shopping - Piso L1 - Loja 1087 (São Paulo)',
    'West Plaza Shopping - Loja 3102 - Bloco A - 2º piso (São Paulo)',
  ];

  // Visibilidade das senhas
  bool _mostrarSenhaAtual = false;
  bool _mostrarNovaSenha = false;
  bool _mostrarConfirmarSenha = false;
  bool _carregandoPerfil = false;

// Aqui ele inicia o programa com os dados mockados 
  @override
  void initState() {
    super.initState();

    _estadoController.text = 'SP';

    _carregarPerfil();
  }
  // Selecionar foto do perfil
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

  // Remover foto do perfil
  void _removerFoto() {
    setState(() {
      _imagemPerfil = null;
    });
  }

 // Função que carrega o pefil do usuário consultado lá no BD
  Future<void> _carregarPerfil() async {
    final usuario = Sessao.usuario;

    if (usuario == null) {
      debugPrint('Nenhum usuário encontrado na sessão.');
      return;
    }

    setState(() {
      _carregandoPerfil = true;
    });

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/perfil',
      ).replace(
        queryParameters: {'id': usuario.id},
      );

      final resposta = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (resposta.statusCode != 200) {
        throw Exception('Erro ao carregar perfil: ${resposta.statusCode}');
      }

      final dados = jsonDecode(
        utf8.decode(resposta.bodyBytes),
      ) as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        _nomeController.text = dados['nome'] ?? '';
        _nomeTerapeuta = dados['nome'] ?? '';

        _emailController.text = dados['email'] ?? '';
        _celularController.text = dados['celular'] ?? '';

        _cepController.text = dados['cep'] ?? '';
        _estadoController.text = dados['estado'] ?? 'SP';

        _ruaController.text = dados['endereco'] ?? '';
        _numeroController.text = dados['numero'] ?? '';
        _complementoController.text = dados['complemento'] ?? '';
        _bairroController.text = dados['bairro'] ?? '';
        _cidadeController.text = dados['cidade'] ?? '';

        final dataNascimento = dados['dataNascimento'] as String?;

        if (dataNascimento != null && dataNascimento.isNotEmpty) {
          _dataNascimentoController.text =
              dataNascimento.split(' ').first;
        }
      });
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar os dados do perfil.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregandoPerfil = false;
        });
      }
    }
  }

  // Buscar endereço automaticamente pelo CEP
  Future<void> _buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'\D'), '');

    if (cepLimpo.length != 8) return;

    try {
      final url = Uri.https(
        'viacep.com.br',
        '/ws/$cepLimpo/json/',
      );

      final resposta = await http.get(url);

      if (resposta.statusCode != 200) return;

      final dados = jsonDecode(resposta.body);

      if (dados['erro'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'CEP não encontrado. Verifique o número digitado.',
            ),
          ),
        );

        return;
      }
      if (!mounted) return;

      setState(() {
        _ruaController.text = dados['logradouro'] ?? '';
        _bairroController.text = dados['bairro'] ?? '';
        _cidadeController.text = dados['localidade'] ?? '';
        _estadoController.text = dados['uf'] ?? '';
      });
    } catch (e) {
      debugPrint('Erro ao consultar CEP: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível consultar o CEP.'),
        ),
      );
    }
  }

  // Pop-up de confirmação de salvamento, por enquanto estará mockado, sem integração com o backend ou com o BD
  // Quando formos mexer na requisição de login, substituir totalmente esse método.
  // Nessa versão, ele NÂO salva, NÂO altera, apenas consullta o SQL e incorpora
  void _confirmarSalvamentoMockado() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.branco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Column(
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
                style: TextStyle(
                  color: AppColors.cinza,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verde,
                foregroundColor: AppColors.branco,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  // Avançar para a próxima aba (Endereço e Mudar Senha)
  void _avancarAba() {
    if (_abaSelecionada < 2) {
      setState(() {
        _abaSelecionada++;
      });
    }
  }

  // Voltar para a aba anterior
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
              // Título
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

              // Layout desktop
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
                // Layout mobile/tablet
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _menuPerfil(),
                    const SizedBox(height: 16),
                    _conteudoAba(mobile: mobile),
                  ],
                ),

              const SizedBox(height: 20),

              // Botões de navegação
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (_abaSelecionada > 0)
                      OutlinedButton.icon(
                        onPressed: _voltarAba,
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 17,
                        ),
                        label: const Text('Voltar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.marrom,
                          side: const BorderSide(
                            color: AppColors.borda,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),

                    if (_abaSelecionada < 2)
                      ElevatedButton.icon(
                        onPressed: _avancarAba,
                        icon: const Icon(
                          Icons.arrow_forward,
                          size: 17,
                        ),
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
                        onPressed: _confirmarSalvamentoMockado,
                        icon: const Icon(
                          Icons.check,
                          size: 17,
                        ),
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
          ),
        );
      },
    );
  }

  // Campo de Estado (UF)
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
          value: _estados.contains(_estadoController.text)
              ? _estadoController.text
              : 'SP',
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.branco,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 17,
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
          items: _estados.map((estado) {
            return DropdownMenuItem<String>(
              value: estado,
              child: Text(estado),
            );
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

  // Campo de Unidade
  Widget _campoUnidade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unidade',
          style: TextStyle(
            color: AppColors.marrom,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        DropdownButtonFormField<String>(
          value: _unidades.contains(_unidadeController.text)
              ? _unidadeController.text
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.branco,
            prefixIcon: const Icon(
              Icons.business_outlined,
              color: AppColors.marrom,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 17,
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
          hint: const Text('Selecione uma unidade'),
          items: _unidades.map((unidade) {
            return DropdownMenuItem<String>(
              value: unidade,
              child: Text(
                unidade,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (unidade) {
            if (unidade == null) return;

            setState(() {
              _unidadeController.text = unidade;
            });
          },
        ),
      ],
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
        border: Border.all(
          color: AppColors.borda,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Foto de perfil
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
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 15,
                        ),
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
              icon: const Icon(
                Icons.photo_camera_outlined,
                size: 16,
              ),
              label: const Text(
                'Adicionar foto',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.verdeFundo,
                foregroundColor: AppColors.marrom,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
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
            style: TextStyle(
              color: AppColors.cinza,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _nomeTerapeuta,
            textAlign: TextAlign.center,
            style: const TextStyle(
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

          const SizedBox(height: 24),

          // Opções de navegação
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
  Widget _conteudoAba({
    required bool mobile,
  }) {
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
  Widget _dadosPessoais({
    required bool mobile,
  }) {
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
            _campoDado(
              'Data de nascimento',
              _dataNascimentoController,
            ),
            _campoDado('E-mail', _emailController),
            _campoDado('Telefone', _telefoneController),
            _campoDado('Celular', _celularController),
          ],
        ),
      ],
    );
  }

  // Aba: Endereço
  Widget _endereco({
    required bool mobile,
  }) {
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
              onChanged: _buscarCep,
            ),
            _campoEstado(),
            _campoDado('Rua', _ruaController),
            _campoDado('Número', _numeroController),
            _campoDado('Complemento', _complementoController),
            _campoDado('Bairro', _bairroController),
            _campoDado('Cidade', _cidadeController),
            _campoUnidade(),
          ],
        ),
      ],
    );
  }

  // Aba: Dados da conta
  Widget _dadosConta({
    required bool mobile,
  }) {
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
            _campoDado(
              'Nome de usuário / Login',
              _loginController,
            ),
            _campoDado(
              'E-mail da conta',
              _emailController,
            ),
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
                  _mostrarConfirmarSenha =
                      !_mostrarConfirmarSenha;
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
    TextEditingController controller, {
    Function(String)? onChanged,
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
          onChanged: onChanged,
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