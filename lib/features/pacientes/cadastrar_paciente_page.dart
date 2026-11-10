
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class CadastrarPacientePage extends StatefulWidget {
  const CadastrarPacientePage({super.key});


  @override
  State<CadastrarPacientePage> createState() =>
      _CadastrarPacientePageState();
}

class _CadastrarPacientePageState extends State<CadastrarPacientePage> {
  Uint8List? _imagemPaciente;

// Controllers para os campos de cadastro
  final TextEditingController _observacoesController =
      TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();

  String _ufSelecionada = 'SP';
  String? _generoSelecionado;


// Função para liberar memória dos controllers quando a página é descartada
  @override
  void dispose() {
    _observacoesController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _dataNascimentoController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();

    super.dispose();
  }

// Função para buscar o endereço a partir do CEP informado
  Future<void> _buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'\D'), '');

    if (cepLimpo.length != 8) return;

    try {
      final url = Uri.https(
        'viacep.com.br',
        '/ws/$cepLimpo/json/',
      );

      final resposta = await http.get(url);

      if (resposta.statusCode != 200) {
        return;
      }

      final dados = jsonDecode(resposta.body);

      if (dados['erro'] == true) {
        return;
      }

      setState(() {
        _ruaController.text = dados['logradouro'] ?? '';
        _bairroController.text = dados['bairro'] ?? '';
        _cidadeController.text = dados['localidade'] ?? '';
        _ufSelecionada = dados['uf'] ?? 'SP';
      });
    } catch (e) {
      debugPrint('Erro ao consultar CEP: $e');
    }
  }

// Função para cadastrar o paciente no banco de dados
  Future<void> _cadastrarPaciente() async {
    final dataDigitada = _dataNascimentoController.text.trim();

    if (_nomeController.text.trim().isEmpty ||
      _telefoneController.text.trim().isEmpty ||
      _cpfController.text.trim().isEmpty ||
      dataDigitada.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complete o cadastro corretamente.'),
      ),
    );
    return;
    }
    final partesData = dataDigitada.split('/');

    if (partesData.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe uma data de nascimento válida.'),
        ),
      );
      return;
    }

    final dataFormatada =
        '${partesData[2]}-${partesData[1]}-${partesData[0]}';

    final genero = switch (_generoSelecionado) {
      'Feminino' => 'F',
      'Masculino' => 'M',
      _ => '',
    };

    final dados = {
      'nome': _nomeController.text.trim(),
      'telefone': _telefoneController.text.trim(),
      'dataNascimento': dataFormatada,
      'email': _emailController.text.trim(),
      'genero': genero,
      'cpf': _cpfController.text.trim(),
      'observacoes': _observacoesController.text.trim(),
      'cep': _cepController.text.trim(),
      'rua': _ruaController.text.trim(),
      'numero': _numeroController.text.trim(),
      'complemento': _complementoController.text.trim(),
      'bairro': _bairroController.text.trim(),
      'cidade': _cidadeController.text.trim(),
      'uf': _ufSelecionada,
    };

    try {
      final resposta = await http.post(
        Uri.parse(
          'http://localhost:8080/api/cadastrar_paciente',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(dados),
      );

      if (!mounted) return;
      final resultado = jsonDecode(resposta.body);
      if (resposta.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Paciente cadastrado!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: const Text(
              'Os dados do paciente foram salvos com sucesso.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  setState(() {
                    _nomeController.clear();
                    _cpfController.clear();
                    _telefoneController.clear();
                    _emailController.clear();
                    _dataNascimentoController.clear();

                    _cepController.clear();
                    _ruaController.clear();
                    _numeroController.clear();
                    _complementoController.clear();
                    _bairroController.clear();
                    _cidadeController.clear();

                    _observacoesController.clear();

                    _generoSelecionado = null;
                    _ufSelecionada = 'SP';
                    _imagemPaciente = null;
                  });
                },
                  style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verde,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Entendi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado['erro'] ?? 'Não foi possível cadastrar o paciente.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível conectar ao servidor.',
          ),
        ),
      );

      debugPrint('Erro ao cadastrar paciente: $e');
    }
  }

// Função para selecionar a foto do paciente
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
      _imagemPaciente = bytes;
    });
  }

  void _removerFoto() {
    setState(() {
      _imagemPaciente = null;
    });
  }

// Seção de máscaras dos campos de cadastro
// Máscaras que adicionam / em "data de nasc" e . no campo de CPF e etc
  static final _mascaraCPF = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  static final _mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  static final _mascaraData = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  static final _mascaraCEP = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );


// Função que inicia a construção da página de cadastro do paciente
    @override
    Widget build(BuildContext context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1100;

          final conteudo = Padding(
            padding: EdgeInsets.symmetric(
              horizontal: desktop ? 20 : 16,
              vertical: desktop ? 4 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cadastrar Paciente',
                  style: TextStyle(
                    color: AppColors.marrom,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Preencha as informações para cadastrar um novo paciente.',
                  style: TextStyle(
                    color: AppColors.cinza,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),

                if (desktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _cartaoDadosPessoais(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _cartaoInformacoesClinicas(),
                            const SizedBox(height: 16),
                            _cartaoPreferencias(),
                            const SizedBox(height: 24),
                            _botoesAcao(), // <- botões na coluna da direita
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _cartaoDadosPessoais(),
                      const SizedBox(height: 20),
                      _cartaoInformacoesClinicas(),
                      const SizedBox(height: 20),
                      _cartaoPreferencias(),
                      const SizedBox(height: 24),
                      _botoesAcao(), // <- botões no fim, no mobile
                    ],
                  ),
              ],
            ),
          );

          return Container(
            width: double.infinity,
            color: AppColors.fundoConteudo,
            child: SingleChildScrollView(
              child: conteudo,
            ),
          );
        },
      );
    }

// Botões de ação: Cancelar e Cadastrar Paciente
Widget _botoesAcao() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      OutlinedButton(
        onPressed: () {
          setState(() {
            _nomeController.clear();
            _cpfController.clear();
            _telefoneController.clear();
            _emailController.clear();
            _dataNascimentoController.clear();

            _cepController.clear();
            _ruaController.clear();
            _numeroController.clear();
            _complementoController.clear();
            _bairroController.clear();
            _cidadeController.clear();

            _observacoesController.clear();

            _generoSelecionado = null;
            _ufSelecionada = 'SP';
            _imagemPaciente = null;
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.marrom,
          side: const BorderSide(color: AppColors.borda),
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('Cancelar'),
      ),
      const SizedBox(width: 12),
      FilledButton.icon(
        onPressed: _cadastrarPaciente,
        icon: const Icon(Icons.check, size: 18),
        label: const Text(
          'Cadastrar paciente',
          style: TextStyle(fontSize: 14),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.verde,
          foregroundColor: AppColors.branco,
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ],
  );
}


// Seção do Cartão: Dados Pessoais no Cadastrar Paciente
Widget _cartaoDadosPessoais() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.branco,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borda),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título Dados pessoais
        Row(
          children: [
            const Icon(
              Icons.person_outline,
              color: AppColors.verdeEscuro,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              'Dados pessoais',
              style: TextStyle(
                color: AppColors.marrom,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Foto reservada e campos pessoais
        LayoutBuilder(
          builder: (context, constraints) {
            final foto = Column(
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
                        child: _imagemPaciente != null
                            ? Image.memory(
                                _imagemPaciente!,
                                width: 112,
                                height: 112,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.person_outline,
                                color: AppColors.cinza,
                                size: 68,
                              ),
                      ),
                    ),

                    if (_imagemPaciente != null)
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
                      style: TextStyle(fontSize: 12, 
                      fontWeight: FontWeight.w600),
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
                  style: TextStyle(
                    color: AppColors.cinza,
                    fontSize: 10,
                  ),
                ),
              ],
            );

            final campos = LayoutBuilder(
              builder: (context, campoConstraints) {
                const espacamento = 16.0;
                final largura =
                    (campoConstraints.maxWidth - espacamento) / 2;

                return Wrap(
                  spacing: espacamento,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: campoConstraints.maxWidth,
                      child: _campo(
                        'Nome completo',
                        obrigatorio: true,
                        hint: 'Digite o nome completo',
                        controller: _nomeController,
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: _campo(
                        'Data de nascimento',
                        obrigatorio: true,
                        hint: 'DD/MM/AAAA',
                        mascara: _mascaraData,
                        teclado: TextInputType.number,
                        controller: _dataNascimentoController,
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: _campo(
                        'CPF',
                        obrigatorio: true,
                        hint: '000.000.000-00',
                        mascara: _mascaraCPF,
                        teclado: TextInputType.number,
                        controller: _cpfController,
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: _campo(
                        'Telefone',
                        obrigatorio: true,
                        hint: '(00) 00000-0000',
                        mascara: _mascaraTelefone,
                        teclado: TextInputType.number,
                        controller: _telefoneController,
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: _campo(
                        'E-mail',
                        hint: 'exemplo@email.com',
                        teclado: TextInputType.emailAddress,
                        controller: _emailController,
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: _campoSelecao(
                        'Gênero',
                        [
                          'Feminino',
                          'Masculino',
                          'Outro',
                          'Prefiro não informar',
                        ],
                        aoAlterar: (novoValor){
                          setState(() {
                            _generoSelecionado = novoValor;
                          });
                        }
                      ),
                    ),
                  ],
                );
              },
            );

            if (constraints.maxWidth >= 560) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 140, child: foto),
                  const SizedBox(width: 20),
                  Expanded(child: campos),
                ],
              );
            }

            return Column(
              children: [
                foto,
                const SizedBox(height: 20),
                campos,
              ],
            );
          },
        ),

        const SizedBox(height: 28),
        const Divider(color: AppColors.cinzaMuitoClaro),
        const SizedBox(height: 24),

        // Seção Endereço
        Row(
          children: [
            const Icon(
              Icons.home_outlined,
              color: AppColors.verdeEscuro,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              'Endereço',
              style: TextStyle(
                color: AppColors.marrom,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        LayoutBuilder(
          builder: (context, constraints) {
            const espacamento = 16.0;
            final largura = constraints.maxWidth;
            final desktop = largura >= 500;
            final disponivelPrimeiraLinha =
                largura - espacamento * 2;
            final disponivelSegundaLinha =
                largura - espacamento * 3;

            final larguraCEP =
                desktop ? disponivelPrimeiraLinha * 0.25 : largura;
            final larguraRua =
                desktop ? disponivelPrimeiraLinha * 0.50 : largura;
            final larguraNumero =
                desktop ? disponivelPrimeiraLinha * 0.25 : largura;

            final larguraComplemento =
                desktop ? disponivelSegundaLinha * 0.30 : largura;
            final larguraBairro =
                desktop ? disponivelSegundaLinha * 0.23 : largura;
            final larguraCidade =
                desktop ? disponivelSegundaLinha * 0.29 : largura;
            final larguraUF =
                desktop ? disponivelSegundaLinha * 0.18 : largura;

            return Wrap(
              spacing: espacamento,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: larguraCEP,
                  child: _campo(
                    'CEP',
                    hint: '00000-000',
                    mascara: _mascaraCEP,
                    teclado: TextInputType.number,
                    controller: _cepController,
                    aoAlterar: _buscarCep,
                  ),
                ),
                SizedBox(
                  width: larguraRua,
                  child: _campo(
                    'Rua',
                    hint: 'Digite o endereço',
                    controller: _ruaController,
                  ),
                ),
                SizedBox(
                  width: larguraNumero,
                  child: _campo(
                    'Número',
                    hint: 'Ex.: 123',
                    controller: _numeroController,
                  ),
                ),
                SizedBox(
                  width: larguraComplemento,
                  child: _campo(
                    'Complemento',
                    hint: 'Ex.: Apto 22, Bloco B',
                    controller: _complementoController,
                  ),
                ),
                SizedBox(
                  width: larguraBairro,
                  child: _campo(
                    'Bairro',
                    hint: 'Digite o bairro',
                    controller: _bairroController,
                  ),
                ),
                SizedBox(
                  width: larguraCidade,
                  child: _campo(
                    'Cidade',
                    hint: 'Digite a cidade',
                    controller: _cidadeController,
                  ),
                ),
                SizedBox(
                  width: larguraUF,
                  child: _campoSelecao(
                    'UF',
                    [
                      'AC', 'AL', 'AP', 'AM', 'BA', 'CE',
                      'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
                      'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
                      'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
                      'SP', 'SE', 'TO',
                    ],
                    valorInicial: _ufSelecionada,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}


// Seção do Cartão: Informações Clínicas no Cadastrar Paciente
  Widget _cartaoInformacoesClinicas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              const Icon(
                Icons.assignment_outlined,
                color: AppColors.verdeEscuro,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Informações clínicas',
                style: TextStyle(
                  color: AppColors.marrom,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _rotulo('Observações iniciais', false),
          const SizedBox(height: 8),

          TextFormField(
            controller: _observacoesController,
            maxLines: 3,
            maxLength: 500,
            decoration: _decoracao(
              'Ex.: demandas, histórico relevante, preferências, etc.',
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _rotulo('Tags', false),
              const SizedBox(width: 6),
              const Text(
                '(opcional)',
                style: TextStyle(
                  color: AppColors.cinza,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tagClinica('Ansiedade'),
              _tagClinica('Estresse'),
              _tagClinica('Depressão'),
              _tagClinica('Autoestima'),
            ],
          ),
        ],
      ),
    );
  }

// Widget das tags clicaveís na descrição do paciente
  Widget _tagClinica(String texto) {
  return _TagClinica(
    texto: texto,
    onTap: () {
      final textoAtual = _observacoesController.text;

      if (!textoAtual.contains(texto)) {
        _observacoesController.text = textoAtual.isEmpty
            ? texto
            : '$textoAtual, $texto';
      }
    },
  );
}

  // Seção do Cartão: Preferencias de Atendimento no Cadastrar Paciente
  Widget _cartaoPreferencias() {
    return Container(
      width: double.infinity,
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
              const Icon(
                Icons.favorite_border,
                color: AppColors.verdeEscuro,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Preferências de atendimento',
                style: TextStyle(
                  color: AppColors.marrom,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _rotulo('Tipo de atendimento', false),
          const SizedBox(height: 10),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _opcaoAtendimento('Particular'),
              _opcaoAtendimento('Convênio'),
              _opcaoAtendimento('Programa de benefícios'),
            ],
          ),

          const SizedBox(height: 20),

          _rotulo('Formato preferido', false),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: _decoracao('Selecione uma opção'),
            items: [
              'Presencial',
              'Online',
              'Híbrido',
            ].map((opcao) {
              return DropdownMenuItem(
                value: opcao,
                child: Text(opcao),
              );
            }).toList(),
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

// Widget que cria a opção de atendimento com checkbox e texto
  Widget _opcaoAtendimento(String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: false,
          onChanged: (_) {},
          activeColor: AppColors.verde,
          visualDensity: VisualDensity.compact,
        ),
        Flexible(
          child: Text(
            texto,
            style: const TextStyle(
              color: AppColors.cinzaEscuro,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

// Função que cria o campo de texto com rótulo, máscara, teclado e controller
  Widget _campo(
    String titulo, {
    bool obrigatorio = false,
    String? hint,
    MaskTextInputFormatter? mascara,
    TextInputType? teclado,
    TextEditingController? controller,
    ValueChanged<String>? aoAlterar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rotulo(titulo, obrigatorio),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: teclado,
          inputFormatters: mascara == null ? [] : [mascara],
          onChanged: aoAlterar,
          decoration: _decoracao(hint),
        ),
      ],
    );
  }

  Widget _campoSelecao(
    String titulo,
    List<String> opcoes, {
    String? valorInicial,
    ValueChanged<String>? aoAlterar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rotulo(titulo, false),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(valorInicial),
          isExpanded: true,
          initialValue: valorInicial,
          decoration: _decoracao('Selecione'),
          items: opcoes.map((opcao) {
            return DropdownMenuItem(
              value: opcao,
              child: Text(opcao),
            );
          }).toList(),
          onChanged: (novoValor) {
            if (novoValor != null) {
              if (aoAlterar != null) {
                aoAlterar(novoValor);
              } else {
                setState(() {
                  _ufSelecionada = novoValor;
                });
              }
            }
          },
        ),
      ],
    );
  }

  Widget _rotulo(String titulo, bool obrigatorio) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.cinzaEscuro,
          fontSize: 14,
        ),
        children: [
          TextSpan(text: titulo),
          if (obrigatorio)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.erro),
            ),
        ],
      ),
    );
  }

  InputDecoration _decoracao(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.cinzaClaro,
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.creme,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: AppColors.verdeEscuro,
          width: 1.5,
        ),
      ),
    );
  }
}

// Classe que cria o widget de tag clicável e selecionavel na descrição do paciente
class _TagClinica extends StatefulWidget {
  final String texto;
  final VoidCallback onTap;

  const _TagClinica({
    required this.texto,
    required this.onTap,
  });

  @override
  State<_TagClinica> createState() => _TagClinicaState();
}

class _TagClinicaState extends State<_TagClinica> {
  bool mouseSobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => mouseSobre = true),
      onExit: (_) => setState(() => mouseSobre = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: AppColors.verdeFundo,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borda),
            boxShadow: mouseSobre
                ? [
                    BoxShadow(
                      color: AppColors.verdeEscuro.withValues(alpha: 0.20),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.texto,
            style: const TextStyle(
              color: AppColors.marrom,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
