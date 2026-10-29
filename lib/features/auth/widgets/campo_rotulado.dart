import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Campo de texto com o título em cima, usado nas telas de autenticação.
class CampoRotulado extends StatelessWidget {
  final String rotulo;
  final TextEditingController controller;
  final bool ocultarTexto;
  final TextInputType? tipoTeclado;
  final Widget? iconeFinal;
  final FormFieldValidator<String>? validador;

  const CampoRotulado({
    super.key,
    required this.rotulo,
    required this.controller,
    this.ocultarTexto = false,
    this.tipoTeclado,
    this.iconeFinal,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            fontSize: 18,
            color: AppColors.textoPrincipal,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: ocultarTexto,
          keyboardType: tipoTeclado,
          validator: validador,
          decoration: InputDecoration(
            fillColor: AppColors.fundoConteudo,
            suffixIcon: iconeFinal,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
