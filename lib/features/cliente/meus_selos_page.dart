import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/sessao.dart';
import '../../core/theme/app_colors.dart';
import '../agenda/datas.dart';
import 'cliente_service.dart';

class MeusSelosPage extends StatefulWidget {
  const MeusSelosPage({super.key});

  @override
  State<MeusSelosPage> createState() => _MeusSelosPageState();
}

class _MeusSelosPageState extends State<MeusSelosPage> {
  late final Future<SelosDados> _dados;

  @override
  void initState() {
    super.initState();
    _dados = ClienteService().buscarSelos();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fundoConteudo,
      child: FutureBuilder<SelosDados>(
        future: _dados,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final erro = snapshot.error;
            return Center(
              child: Text(
                erro is ClienteException
                    ? erro.mensagem
                    : 'Não foi possível carregar seus selos.',
                style: const TextStyle(color: AppColors.erro),
              ),
            );
          }

          final dados = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final largo = constraints.maxWidth >= 900;
              final espaco = largo ? 20.0 : 16.0;

              return SingleChildScrollView(
                padding: EdgeInsets.all(largo ? 28 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FaixaDeNumeros(dados: dados, largo: largo),
                    SizedBox(height: espaco),
                    
                    if (largo)
                      
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 3, child: _CartaoDeSelos(dados: dados)),
                            SizedBox(width: espaco),
                            Expanded(
                              flex: 2,
                              child: _ProximaSessao(sessao: dados.proximaSessao),
                            ),
                          ],
                        ),
                      )

                    else ...[
                      _CartaoDeSelos(dados: dados),
                      SizedBox(height: espaco),
                      _ProximaSessao(sessao: dados.proximaSessao),
                    ],
                    SizedBox(height: espaco),
                    _Historico(historico: dados.historico),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}



class _FaixaDeNumeros extends StatelessWidget {
  final SelosDados dados;
  final bool largo;

  const _FaixaDeNumeros({required this.dados, required this.largo});

  @override
  Widget build(BuildContext context) {
    final desde = dados.clienteDesde;
    final itens = [
      _CartaoNumero(
        icone: Icons.stars,
        valor: '${dados.saldo}',
        legenda: dados.saldo == 1 ? 'selo agora' : 'selos agora',
      ),
      _CartaoNumero(
        icone: Icons.spa_outlined,
        valor: '${dados.sessoes}',
        legenda: dados.sessoes == 1 ? 'sessão feita' : 'sessões feitas',
      ),
      _CartaoNumero(
        icone: Icons.card_giftcard,
        valor: '${dados.resgates}',
        legenda: dados.resgates == 1
            ? 'recompensa resgatada'
            : 'recompensas resgatadas',
      ),
      _CartaoNumero(
        icone: Icons.favorite_border,
        valor: desde == null ? '—' : _mesAno(desde),
        legenda: 'cliente desde',
      ),
    ];


    if (largo) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < itens.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: itens[i]),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var linha = 0; linha < 2; linha++) ...[
          if (linha > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: itens[linha * 2]),
                const SizedBox(width: 12),
                Expanded(child: itens[linha * 2 + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CartaoNumero extends StatelessWidget {
  final IconData icone;
  final String valor;
  final String legenda;

  const _CartaoNumero({
    required this.icone,
    required this.valor,
    required this.legenda,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoCartao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22, color: AppColors.verde),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(
            legenda,
            style: const TextStyle(fontSize: 13, color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}


class _CartaoDeSelos extends StatelessWidget {
  final SelosDados dados;

  const _CartaoDeSelos({required this.dados});

  static const _colunas = 5;
  static const _linhas = 3;

  @override
  Widget build(BuildContext context) {
    final total = _colunas * _linhas;
    final preenchidos = min(dados.saldo, total);
    final proxima = dados.proxima;
    final primeiroNome = Sessao.usuario?.nome.split(' ').first ?? '';
    final branco = AppColors.branco;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.verde, AppColors.verdeEscuro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              bottom: -40,
              child: _Octogono(
                tamanho: 200,
                cor: branco.withValues(alpha: 0.12),
                corTexto: branco.withValues(alpha: 0.18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ROKUZEN',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: branco,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        'Cartão fidelidade',
                        style: TextStyle(color: branco.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 3 linhas de 5 selos
                  for (var linha = 0; linha < _linhas; linha++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var coluna = 0; coluna < _colunas; coluna++)
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: _selo(linha * _colunas + coluna < preenchidos),
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text(
                    '$primeiroNome · $preenchidos de $total selos',
                    style: TextStyle(
                      color: branco,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (proxima != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: preenchidos / total,
                        minHeight: 8,
                        color: branco,
                        backgroundColor: branco.withValues(alpha: 0.25),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      proxima.selos - dados.saldo == 1
                          ? 'Falta 1 selo para: ${proxima.nome} 🎁'
                          : 'Faltam ${proxima.selos - dados.saldo} selos para: '
                              '${proxima.nome} 🎁',
                      style: TextStyle(color: branco),
                    ),


                  ] else
                    Text(
                      'Você já pode resgatar qualquer recompensa! 🎉',
                      style: TextStyle(color: branco),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selo(bool cheio) {
    return _Octogono(
      tamanho: 44,
      cor: cheio
          ? AppColors.branco
          : AppColors.branco.withValues(alpha: 0.25),
      corTexto: cheio
          ? AppColors.verdeEscuro
          : AppColors.branco.withValues(alpha: 0.5),
    );
  }
}

class _Octogono extends StatelessWidget {
  final double tamanho;
  final Color cor;
  final Color corTexto;

  const _Octogono({
    required this.tamanho,
    required this.cor,
    required this.corTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: cor,
        // Octógono com o lado de cima reto, como no logo
        shape: const StarBorder.polygon(sides: 8, rotation: 22.5),
      ),
      child: Text(
        '六',
        style: TextStyle(fontSize: tamanho * 0.45, color: corTexto),
      ),
    );
  }
}


class _ProximaSessao extends StatelessWidget {
  final ProximaSessao? sessao;

  const _ProximaSessao({required this.sessao});

  @override
  Widget build(BuildContext context) {
    final sessao = this.sessao;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decoracaoCartao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Título no topo, sessão no meio e destaque no rodapé
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.event_available, size: 20),
              SizedBox(width: 8),
              Text(
                'Sua próxima sessão',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: sessao == null ? _semSessao() : _comSessao(sessao),
          ),
          _destaque(
            sessao == null
                ? 'Agende sua próxima sessão e ganhe mais um selo!'
                : 'Essa sessão vale +1 selo!',
          ),
        ],
      ),
    );
  }

  Widget _comSessao(ProximaSessao sessao) {
    return Row(
      children: [
        Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.verdeFundo,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                '${sessao.inicio.day}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.verdeMuitoEscuro,
                ),
              ),
              Text(
                _mesesCurtos[sessao.inicio.month - 1].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.verdeEscuro,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${diaPorExtenso(sessao.inicio).split(',').first} · '
                '${hora(sessao.inicio)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              _linha(Icons.spa_outlined, sessao.servico),
              if (sessao.unidade != null)
                _linha(Icons.place_outlined, sessao.unidade!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _semSessao() {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 48, color: AppColors.cinzaClaro),
          SizedBox(height: 8),
          Text(
            'Você não tem nenhuma sessão marcada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }

  Widget _linha(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icone, size: 16, color: AppColors.verde),
          const SizedBox(width: 6),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }

  Widget _destaque(String texto) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.verdeFundo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: AppColors.verde),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}



class _Historico extends StatelessWidget {
  final List<SeloGanho> historico;

  const _Historico({required this.historico});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decoracaoCartao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 20),
              SizedBox(width: 8),
              Text(
                'Como você ganhou seus selos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (historico.isEmpty)
            const Text(
              'Seus selos aparecem aqui depois de cada sessão.',
              style: TextStyle(color: AppColors.textoSecundario),
            )
          else
            for (final selo in historico)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: AppColors.verde),
                    const SizedBox(width: 8),
                    Expanded(child: Text(selo.servico)),
                    Text(
                      _formatarData(selo.data),
                      style: const TextStyle(color: AppColors.textoSecundario),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}


final _decoracaoCartao = BoxDecoration(
  color: AppColors.branco,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.borda),
);

const _mesesCurtos = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

/// Ex.: mar/2025
String _mesAno(DateTime data) => '${_mesesCurtos[data.month - 1]}/${data.year}';

String _formatarData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/${data.year}';
