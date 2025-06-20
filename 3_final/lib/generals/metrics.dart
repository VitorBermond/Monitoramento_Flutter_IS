import 'package:fl_chart/fl_chart.dart';

// EXEMPLO DE USO:
//   final tpDataStore = MetricDataManager.getInstance("tp");
// Isso criará um conjunto de dados para poder ser utilizado nos gráficos, com nome de instância "tp",
// referenciada a variável tpDataStore

/// Classe que armazena dados de uma métrica (CPU, GPU, TP etc.) [DataStore]
class MetricData {
  final Map<String, List<FlSpot>> realData = {};
  final Map<String, List<FlSpot>> histData = {};

  final Map<String, List<String>> timeLabelsReal = {};
  final Map<String, List<String>> timeLabelsHist = {};

  final Map<String, List<int>> timeEpochsReal = {};
  final Map<String, List<int>> timeEpochsHist = {};

  final Map<int, String> servicesList = {};
  final Map<String, bool> lineVisibility = {};

  int indexReal = 0;

  /// Reseta completamente o datastore, deixando todos os mapas vazios.
  /// chama-se com DataStore.reset();
  void reset() {
    realData.clear();
    histData.clear();
    timeLabelsReal.clear();
    timeLabelsHist.clear();
    timeEpochsReal.clear();
    timeEpochsHist.clear();
    servicesList.clear();
    lineVisibility.clear();
  }
}

/// Gerenciador que retorna uma instância de dados única de MetricData por nome
class MetricDataManager {
  static final Map<String, MetricData> _instances = {};

  /// Obtém uma instância persistente associada a uma métrica, como "cpu", "gpu", "pt"
  static MetricData getInstance(String metricName) {
    return _instances.putIfAbsent(metricName, () => MetricData());
  }
}
