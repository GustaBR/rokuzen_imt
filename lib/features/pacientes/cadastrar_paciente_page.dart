
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';


class CadastrarPacientePage extends StatefulWidget {
  const CadastrarPacientePage({super.key});

  @override
  State<CadastrarPacientePage> createState() =>
      _CadastrarPacientePageState();
}

class _CadastrarPacientePageState extends State<CadastrarPacientePage> {
  Uint8List? _imagemPaciente;

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

@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 1100;

      final conteudo = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: desktop ? 20 : 16,
          vertical: desktop ? 12 : 20,
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
                ],
              ),
          ],
        ),
      );

      return Container(
        width: double.infinity,
        color: AppColors.fundoConteudo,
        child: desktop
            ? conteudo
            : SingleChildScrollView(
                child: conteudo,
              ),
      );
    },
  );
}


  
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
              ClipOval(
                child: Container(
                  width: 100,
                  height: 100,
                  color: AppColors.verdeFundo,
                  child: _imagemPaciente != null
                      ? Image.memory(
                          _imagemPaciente!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.person_outline,
                          color: AppColors.cinza,
                          size: 48,
                        ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: 120,
                child: FilledButton.icon(
                  onPressed: _selecionarFoto,
                  icon: const Icon(
                    Icons.photo_camera_outlined,
                    size: 16,
                  ),
                  label: const Text(
                    'Adicionar foto',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.verdeFundo,
                    foregroundColor: AppColors.marrom,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

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
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: _campo(
                        'CPF',
                        hint: '000.000.000-00',
                        mascara: _mascaraCPF,
                        teclado: TextInputType.number,
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
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: _campo(
                        'E-mail',
                        hint: 'exemplo@email.com',
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
                  SizedBox(width: 110, child: foto),
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
                  ),
                ),
                SizedBox(
                  width: larguraRua,
                  child: _campo(
                    'Rua',
                    hint: 'Digite o endereço',
                  ),
                ),
                SizedBox(
                  width: larguraNumero,
                  child: _campo(
                    'Número',
                    hint: 'Ex.: 123',
                  ),
                ),
                SizedBox(
                  width: larguraComplemento,
                  child: _campo(
                    'Complemento',
                    hint: 'Ex.: Apto 22, Bloco B',
                  ),
                ),
                SizedBox(
                  width: larguraBairro,
                  child: _campo(
                    'Bairro',
                    hint: 'Digite o bairro',
                  ),
                ),
                SizedBox(
                  width: larguraCidade,
                  child: _campo(
                    'Cidade',
                    hint: 'Digite a cidade',
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
                    valorInicial: 'SP',
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

  Widget _tagClinica(String texto) {
    return Chip(
      label: Text(
        texto,
        style: const TextStyle(
          color: AppColors.marrom,
          fontSize: 12,
        ),
      ),
      backgroundColor: AppColors.verdeFundo,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
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

  Widget _campo(
    String titulo, {
    bool obrigatorio = false,
    String? hint,
    MaskTextInputFormatter? mascara,
    TextInputType? teclado,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rotulo(titulo, obrigatorio),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: teclado,
          inputFormatters: mascara == null ? [] : [mascara],
          decoration: _decoracao(hint),
        ),
      ],
    );
  }

  Widget _campoSelecao(
    String titulo,
    List<String> opcoes, {
    String? valorInicial,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rotulo(titulo, false),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: valorInicial,
          decoration: _decoracao('Selecione'),
          items: opcoes.map((opcao) {
            return DropdownMenuItem(
              value: opcao,
              child: Text(opcao),
            );
          }).toList(),
          onChanged: (_) {},
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
