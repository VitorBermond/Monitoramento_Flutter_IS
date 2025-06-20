import 'package:flutter/material.dart';
import 'package:monitoramentoapp/generals/metrics.dart';
import 'package:monitoramentoapp/generals/globals.dart';

class ServiceVisibilityButtons extends StatelessWidget {
  final MetricData dataStore;
  final VoidCallback onVisibilityToggled;

  const ServiceVisibilityButtons({
    super.key,
    required this.dataStore,
    required this.onVisibilityToggled,
  });

  /// Formata valores dinamicamente com base em sua magnitude
  String formatarValor(double valor) {
    if (valor == 0) return '0';
    double abs = valor.abs();

    if (abs < 0.001) {
      return valor.toStringAsExponential(2);
    } else if (abs < 1) {
      return valor.toStringAsFixed(4);
    } else if (abs < 100) {
      return valor.toStringAsFixed(2);
    } else {
      return valor.toStringAsFixed(0);
    }
  }

  /// Calcula a média dos valores (eixo Y) de um serviço, considerando o modo
  double _averageFor(String serviceName) {
    final dataMap = isRealTime ? dataStore.realData : dataStore.histData;
    final list = dataMap[serviceName];
    if (list == null || list.isEmpty) return 0;
    final sum = list.fold<double>(0, (acc, spot) => acc + spot.y);
    return sum / list.length;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dataStore.servicesList.entries.map((entry) {
        final index = entry.key;
        final serviceName = entry.value;
        final isVisible = dataStore.lineVisibility[serviceName] ?? true;
        final color = listaCores[index % listaCores.length];
        final avg = _averageFor(serviceName);

        return SizedBox(
          width: 110,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape:
                  const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            ),
            onPressed: () {
              dataStore.lineVisibility[serviceName] = !isVisible;
              onVisibilityToggled();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${isVisible ? "✅" : "🚫"} $serviceName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'x̄: ${formatarValor(avg)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
