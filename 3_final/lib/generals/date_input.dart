import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Agrupa os controladores de campos de data e hora
class DateTimeControllers {
  final TextEditingController year = TextEditingController();
  final TextEditingController month = TextEditingController();
  final TextEditingController day = TextEditingController();
  final TextEditingController hour = TextEditingController();
  final TextEditingController minute = TextEditingController();

  void dispose() {
    year.dispose();
    month.dispose();
    day.dispose();
    hour.dispose();
    minute.dispose();
  }
}

/// Widget que exibe uma linha de campos de data/hora reutilizável
class DateTimeInputRow extends StatelessWidget {
  final String labelPrefix;
  final DateTimeControllers controllers;

  const DateTimeInputRow({
    super.key,
    required this.labelPrefix,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildField("Ano", controllers.year, now.year.toString(), 4),
        const SizedBox(width: 5),
        _buildField("Mês", controllers.month, now.month.toString(), 2),
        const SizedBox(width: 5),
        _buildField("Dia", controllers.day, now.day.toString(), 2),
        const SizedBox(width: 5),
        _buildField("Hora", controllers.hour, now.hour.toString(), 2),
        const SizedBox(width: 5),
        _buildField(
          "Min.",
          controllers.minute,
          labelPrefix.toLowerCase().contains("final") ? '59' : '00',
          2,
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint,
    int maxLength,
  ) {
    return SizedBox(
      width: 100,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: "$label $labelPrefix",
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          counterText: '',
          border: const OutlineInputBorder(),
          labelStyle: const TextStyle(color: Colors.black),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
        maxLength: maxLength,
      ),
    );
  }
}
