import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CampoHora extends StatelessWidget {
  final String rotulo;
  final TimeOfDay valor;

  
  final List<int> horas;
  final ValueChanged<TimeOfDay> aoMudar;

  
  static const minutos = [0, 15, 30, 45];

  const CampoHora({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.horas,
    required this.aoMudar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            rotulo,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: valor.hour,
            decoration: decoracaoDeDialogo('hora'),
            menuMaxHeight: 300,
            items: [
              for (final hora in horas)
                DropdownMenuItem(
                  value: hora,
                  child: Text(hora.toString().padLeft(2, '0')),
                ),
            ],
            onChanged: (hora) {
              if (hora == null) return;
              aoMudar(TimeOfDay(hour: hora, minute: valor.minute));
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(':', style: TextStyle(fontSize: 20)),
        ),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: valor.minute,
            decoration: decoracaoDeDialogo('min'),
            items: [
              for (final minuto in minutos)
                DropdownMenuItem(
                  value: minuto,
                  child: Text(minuto.toString().padLeft(2, '0')),
                ),
            ],
            onChanged: (minuto) {
              if (minuto == null) return;
              aoMudar(TimeOfDay(hour: valor.hour, minute: minuto));
            },
          ),
        ),
      ],
    );
  }
}

InputDecoration decoracaoDeDialogo(String rotulo, {String? dica}) {
  return InputDecoration(
    labelText: rotulo,
    hintText: dica,
    filled: true,
    fillColor: AppColors.creme,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.cinzaClaro),
    ),
  );
}
