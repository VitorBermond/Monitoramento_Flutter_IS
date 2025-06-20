import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:monitoramentoapp/generals/globals.dart';

class CPUUsageData {
  static final CPUUsageData _instance = CPUUsageData._internal();
  factory CPUUsageData() => _instance;
  CPUUsageData._internal();

  final Map<String, List<FlSpot>> cpuDataReal = {};
  final Map<String, List<FlSpot>> cpuDataHist = {};
  final Map<String, List<String>> timeLabelsReal = {};
  final Map<String, List<String>> timeLabelsHist = {};
  final Map<String, List<int>> timeEpochsReal = {};
  final Map<String, List<int>> timeEpochsHist = {};

  //Map<String, double> timeIndexReal = {};

  // Lista com nomes dos serviços
  final Map<int, String> servicesList = {};
  // Cada chave representa o ID dos Maps e o valor define se ele será exibido no gráfico.
  final Map<String, bool> lineVisibility = {};
}

class CPUUsageScreen extends StatefulWidget {
  const CPUUsageScreen({super.key});

  @override
  State<CPUUsageScreen> createState() => _CPUUsageScreenState();
}

class _CPUUsageScreenState extends State<CPUUsageScreen> {
  final CPUUsageData dataStore = CPUUsageData();
  late Client client;

  // Controladoras das caixas de texto

  final TextEditingController startYearController = TextEditingController();
  final TextEditingController startMonthController = TextEditingController();
  final TextEditingController startDayController = TextEditingController();
  final TextEditingController startHourController = TextEditingController();
  final TextEditingController startMinuteController = TextEditingController();

  final TextEditingController endYearController = TextEditingController();
  final TextEditingController endMonthController = TextEditingController();
  final TextEditingController endDayController = TextEditingController();
  final TextEditingController endHourController = TextEditingController();
  final TextEditingController endMinuteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectToRabbitMQ();
    _listenToHistCPU();
  }

  void _connectToRabbitMQ() async {
    try {
      client = Client(settings: ConnectionSettings(host: hostIp));

      final channel = await client.channel();
      final queue = await channel.queue("Data.CPU", durable: false);

      queue.consume().then((Consumer consumer) {
        consumer.listen((AmqpMessage message) {
          final data = jsonDecode(message.payloadAsString);
          double cpuValue = (data['cpu_usage'] as num).toDouble(); // Ex: 50
          String serviceName = data['service_name']; // Ex: "Service1"
          int timestampEpoch =
              (data['timestamp'] as num).toInt(); // Ex: 1745927603

          // Transforma Unix Epoch em string formatada
          String formattedTime = DateFormat("📅dd/MM/yy\n🕒HH:mm:ss").format(
            DateTime.fromMillisecondsSinceEpoch(timestampEpoch * 1000)
                .toLocal(),
          );

          setState(() {
            // Adiciona o nome à lista de serviços, se ainda não estiver
            if (!dataStore.servicesList.containsValue(serviceName)) {
              int newKey = dataStore.servicesList.length;
              dataStore.servicesList[newKey] = serviceName;
            }

            // Inicializa os mapas, usando serviceName como chave
            dataStore.cpuDataReal.putIfAbsent(serviceName, () => []);
            dataStore.timeLabelsReal.putIfAbsent(serviceName, () => []);
            dataStore.timeEpochsReal.putIfAbsent(serviceName, () => []);

            // Remove o primeiro ponto se exceder o limite
            if ((dataStore.cpuDataReal[serviceName]?.length ?? 0) >=
                maxPoints) {
              dataStore.cpuDataReal[serviceName]?.removeAt(0);
              dataStore.timeLabelsReal[serviceName]?.removeAt(0);
              dataStore.timeEpochsReal[serviceName]?.removeAt(0);
            }

            // Adiciona os dados ao gráfico e aos rótulos
            dataStore.cpuDataReal[serviceName]!.add(
              FlSpot(timestampEpoch.toDouble(), cpuValue),
            );
            dataStore.timeLabelsReal[serviceName]!.add(formattedTime);
            dataStore.timeEpochsReal[serviceName]!.add(timestampEpoch);
          });
        });
      });
    } catch (e) {
      debugPrint("Erro ao conectar ao RabbitMQ: $e");
    }
  }

  void _listenToHistCPU() {
    const fila = 'Hist.CPU';

    client.channel().then((Channel channel) {
      return channel.queue(fila, durable: false);
    }).then((Queue queue) {
      queue.consume().then((Consumer consumer) {
        consumer.listen((AmqpMessage message) {
          try {
            final payload = jsonDecode(message.payloadAsString);

            if (payload is Map<String, dynamic> &&
                payload.containsKey('historico')) {
              final data = payload['historico'];
              final serviceName = payload['service_name']?.toString() ?? '0';

              if (data is List<dynamic>) {
                setState(() {
                  if (!dataStore.servicesList.containsValue(serviceName)) {
                    final newKey = dataStore.servicesList.length;
                    dataStore.servicesList[newKey] = serviceName;
                  }

                  dataStore.cpuDataHist.putIfAbsent(serviceName, () => []);
                  dataStore.cpuDataHist[serviceName]?.clear();
                  dataStore.timeLabelsHist.putIfAbsent(serviceName, () => []);
                  dataStore.timeLabelsHist[serviceName]?.clear();
                  dataStore.timeEpochsHist.putIfAbsent(serviceName, () => []);
                  dataStore.timeEpochsHist[serviceName]?.clear();

                  int timeIndex =
                      0; // Nova contagem de índices para dados Downsamplados

                  for (var entry in data) {
                    if (entry is Map<String, dynamic> &&
                        entry["cpu_usage"] != null &&
                        entry["timestamp"] != null) {
                      dataStore.cpuDataHist[serviceName]!.add(FlSpot(
                        timeIndex.toDouble(),
                        (entry["cpu_usage"] as num).toDouble(),
                      ));

                      int timestampEpoch = (entry["timestamp"] as num).toInt();
                      String formattedTime =
                          DateFormat("📅dd/MM/yy\n🕒HH:mm:ss").format(
                        DateTime.fromMillisecondsSinceEpoch(
                                timestampEpoch * 1000)
                            .toLocal(),
                      );

                      dataStore.timeLabelsHist[serviceName]!.add(formattedTime);
                      dataStore.timeEpochsHist[serviceName]!
                          .add(timestampEpoch);

                      timeIndex++;
                    }
                  }

                  isRealTime = false;
                  _applyDownsampling(serviceName);
                });
              } else {
                debugPrint(
                    "Erro: 'historico' não é uma lista. Recebido: $data");
              }
            } else {
              debugPrint("Erro: Payload inválido em $fila. Recebido: $payload");
            }
          } catch (e) {
            debugPrint("Erro ao decodificar payload de $fila: $e");
          }
        });
      });
    });
  }

  void _applyDownsampling(String serviceName) {
    if (!dataStore.cpuDataHist.containsKey(serviceName) ||
        dataStore.cpuDataHist[serviceName]!.length <= maxPoints) {
      return;
    }

    final List<FlSpot> originalData = dataStore.cpuDataHist[serviceName]!;
    final List<String> originalLabels =
        dataStore.timeLabelsHist[serviceName] ?? [];
    final List<int> originalEpochs =
        dataStore.timeEpochsHist[serviceName] ?? [];

    final int step = (originalData.length / maxPoints).ceil();
    final List<FlSpot> downsampledData = [];
    final List<String> downsampledLabels = [];
    final List<int> downsampledEpochs = [];

    int newIndex = 0; // Começa do zero para o novo eixo X

    for (int i = 0; i < originalData.length; i += step) {
      int end =
          (i + step < originalData.length) ? i + step : originalData.length;

      double sumY = 0;
      double sumEpoch = 0;

      for (int k = i; k < end; k++) {
        sumY += originalData[k].y;
        if (k < originalEpochs.length) {
          sumEpoch += originalEpochs[k];
        }
      }

      int count = end - i;
      double avgY = sumY / count;
      double avgEpoch = sumEpoch / count;

      downsampledData.add(FlSpot(newIndex.toDouble(), avgY));

      int midpointIndex = (i + end) ~/ 2;
      if (midpointIndex < originalLabels.length) {
        downsampledLabels.add(originalLabels[midpointIndex]);
      }
      if (midpointIndex < originalEpochs.length) {
        downsampledEpochs.add(avgEpoch.round());
      }

      newIndex++;
    }

    dataStore.cpuDataHist[serviceName] = downsampledData;
    dataStore.timeLabelsHist[serviceName] = downsampledLabels;
    dataStore.timeEpochsHist[serviceName] = downsampledEpochs;
  }

  void _requestHistoricalData() {
    try {
      final now = DateTime.now();

      // Constrói o DateTime de início considerando o fuso horário do Brasil (UTC-3)
      final start = DateTime(
        int.tryParse(startYearController.text) ?? now.year,
        int.tryParse(startMonthController.text) ?? now.month,
        int.tryParse(startDayController.text) ?? now.day,
        int.tryParse(startHourController.text) ?? now.hour,
        int.tryParse(startMinuteController.text) ?? 0,
      ).subtract(Duration(hours: 0));

      // Constrói o DateTime de fim considerando o fuso horário do Brasil (UTC-3)
      final end = DateTime(
        int.tryParse(endYearController.text) ?? now.year,
        int.tryParse(endMonthController.text) ?? now.month,
        int.tryParse(endDayController.text) ?? now.day,
        int.tryParse(endHourController.text) ?? now.hour,
        int.tryParse(endMinuteController.text) ?? 59,
      ).subtract(Duration(hours: 0));

      // Converte para timestamps em segundos (Unix epoch)
      final int startTimestamp = start.toUtc().millisecondsSinceEpoch ~/ 1000;
      final int endTimestamp = end.toUtc().millisecondsSinceEpoch ~/ 1000;

      final channel = client.channel();
      channel.then((Channel ch) {
        ch.queue("HistRequest.CPU", durable: false).then((Queue queue) {
          final request = jsonEncode({
            "start_datetime": startTimestamp,
            "end_datetime": endTimestamp,
            "services_list": dataStore.servicesList.values.toList(),
          });
          queue.publish(request);
          debugPrint("Requisição enviada com sucesso: $request");
        });
      });
    } catch (e) {
      debugPrint("Erro ao enviar requisição de histórico: $e");
    }
  }

  void _toggleMode() {
    setState(() {
      isRealTime = !isRealTime;
    });
  }

  @override
  void dispose() {
    client.close();

    startYearController.dispose();
    startMonthController.dispose();
    startDayController.dispose();
    startHourController.dispose();
    startMinuteController.dispose();

    endYearController.dispose();
    endMonthController.dispose();
    endDayController.dispose();
    endHourController.dispose();
    endMinuteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monitor de CPU")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: startYearController,
                    decoration: InputDecoration(
                      labelText: "Ano Inicial",
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '${DateTime.now().year}',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    maxLength: 4,
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: startMonthController,
                    decoration: InputDecoration(
                      labelText: "Mês Inicial",
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '${DateTime.now().month}',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    maxLength: 2,
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: startDayController,
                    decoration: InputDecoration(
                      labelText: "Dia Inicial",
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '${DateTime.now().day}',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    maxLength: 2,
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: startHourController,
                    decoration: InputDecoration(
                      labelText: "Hora Inicial",
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '${DateTime.now().hour}',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    maxLength: 2,
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: startMinuteController,
                    decoration: InputDecoration(
                      labelText: "Min. Inicial",
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    maxLength: 2,
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _toggleMode,
                    child:
                        Text(isRealTime ? "Modo Histórico" : "Modo Tempo Real"),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: endYearController,
                    decoration: InputDecoration(
                      labelText: "Ano Final",
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '${DateTime.now().year}',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    maxLength: 4,
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: endMonthController,
                    decoration: InputDecoration(
                      labelText: "Mês Final",
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '${DateTime.now().month}',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    maxLength: 2,
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: endDayController,
                    decoration: InputDecoration(
                      labelText: "Dia Final",
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '${DateTime.now().day}',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    maxLength: 2,
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: endHourController,
                    decoration: InputDecoration(
                      labelText: "Hora Final",
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '${DateTime.now().hour}',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    maxLength: 2,
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: endMinuteController,
                    decoration: InputDecoration(
                      labelText: "Min. Final",
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '59',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    maxLength: 2,
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _requestHistoricalData,
                    child: const Text("Buscar Histórico"),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6.0,
              runSpacing: 6.0,
              children: List.generate(dataStore.servicesList.length, (index) {
                final serviceName = dataStore.servicesList[index] ?? 'S$index';
                final isVisible =
                    dataStore.lineVisibility[serviceName] ?? false;

                return SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: listaCores[index % listaCores.length],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        dataStore.lineVisibility[serviceName] =
                            !(dataStore.lineVisibility[serviceName] ?? false);
                      });
                    },
                    child: Text(
                      '${isVisible ? "✅" : "🚫"} $serviceName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 5),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final allEpochs = <int>[];
                            final allLabels = <String>[];
                            final allXs = <double>[];

                            final labelMap = isRealTime
                                ? dataStore.timeLabelsReal
                                : dataStore.timeLabelsHist;
                            final epochMap = isRealTime
                                ? dataStore.timeEpochsReal
                                : dataStore.timeEpochsHist;
                            final dataMap = isRealTime
                                ? dataStore.cpuDataReal
                                : dataStore.cpuDataHist;

                            for (final serviceName in dataMap.keys) {
                              final dataList = dataMap[serviceName];
                              final labels = labelMap[serviceName];
                              final epochs = epochMap[serviceName];

                              if (dataList != null &&
                                  labels != null &&
                                  epochs != null) {
                                final len = [
                                  dataList.length,
                                  labels.length,
                                  epochs.length
                                ].reduce((a, b) => a < b ? a : b);

                                for (int j = 0; j < len; j++) {
                                  allEpochs.add(epochs[j]);
                                  allLabels.add(labels[j]);
                                  allXs.add(dataList[j].x);
                                }
                              }
                            }

                            if (allEpochs.isEmpty ||
                                allLabels.isEmpty ||
                                allXs.isEmpty) {
                              return Container();
                            }

                            // Em vez de pegar minX e maxX, vamos pegar diretamente o menor X e o maior X:
                            double? leftMostX;
                            String? leftMostLabel;
                            double? rightMostX;
                            String? rightMostLabel;

                            for (int i = 0; i < allXs.length; i++) {
                              if (leftMostX == null || allXs[i] < leftMostX) {
                                leftMostX = allXs[i];
                                leftMostLabel = allLabels[i];
                              }
                              if (rightMostX == null || allXs[i] > rightMostX) {
                                rightMostX = allXs[i];
                                rightMostLabel = allLabels[i];
                              }
                            }

                            // Agora colocamos uma tolerância maior para comparar
                            const double tolerance =
                                0.5; // aumentei a tolerância para pegar os valores arredondados

                            if (leftMostX != null &&
                                (value - leftMostX).abs() < tolerance) {
                              return Text(
                                leftMostLabel ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black),
                                textAlign: TextAlign.center,
                              );
                            } else if (rightMostX != null &&
                                (value - rightMostX).abs() < tolerance) {
                              return Text(
                                rightMostLabel ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black),
                                textAlign: TextAlign.center,
                              );
                            }

                            return Container();
                          }),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles:
                            true, // Ativa os títulos, mas não mostra devido a configuração do widget
                        getTitlesWidget: (value, meta) =>
                            const SizedBox.shrink(), // Oculta o conteúdo
                        reservedSize: 20, // Reserva espaço visual
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  // Criação das linhas e pontos do gráfico
                  lineBarsData: dataStore.servicesList.values
                      .map((serviceName) {
                        final bool visible =
                            dataStore.lineVisibility[serviceName] ?? true;
                        final List<FlSpot> spots = isRealTime
                            ? dataStore.cpuDataReal[serviceName] ?? []
                            : dataStore.cpuDataHist[serviceName] ?? [];
                        dataStore.lineVisibility
                            .putIfAbsent(serviceName, () => true);

                        // Não cria a linha se estiver invisível ou vazia
                        if (!visible || spots.isEmpty) return null;

                        // Define a cor com base na posição do serviço na lista
                        final colorIndex = dataStore.servicesList.values
                                .toList()
                                .indexOf(serviceName) %
                            listaCores.length;

                        // configurações da construção das linhas
                        return LineChartBarData(
                          show: true,
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          barWidth: 2.5,
                          preventCurveOverShooting: true,
                          color: listaCores[colorIndex],
                          isStrokeCapRound: true,
                          isStrokeJoinRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        );
                      })
                      .whereType<LineChartBarData>()
                      .toList(),

                  // Corta qualquer coisa que ultrapassar a box do gráfico
                  // clipData: FlClipData.all(),

                  // ANIMAÇÃO DE TOQUE NOS PONTOS DO GRÁFICO
                  lineTouchData: LineTouchData(
                    touchSpotThreshold:
                        12, // Distância em pixels para considerar um toque no ponto do gráfico
                    handleBuiltInTouches: true,
                    distanceCalculator: (touchPoint, spotPixelCoordinates) =>
                        (touchPoint - spotPixelCoordinates).distance,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 0,
                      getTooltipColor: (_) => Colors.white,
                      tooltipBorder: BorderSide(
                        color: Colors.black,
                        width: 1,
                      ),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final value = touchedSpot.y.toStringAsFixed(2);
                          final serviceNames = isRealTime
                              ? dataStore.cpuDataReal.keys.toList()
                              : dataStore.cpuDataHist.keys.toList();

                          String serviceName = (touchedSpot.barIndex >= 0 &&
                                  touchedSpot.barIndex < serviceNames.length)
                              ? serviceNames[touchedSpot.barIndex]
                              : "";

                          List<String> labels = isRealTime
                              ? dataStore.timeLabelsReal[serviceName] ?? []
                              : dataStore.timeLabelsHist[serviceName] ?? [];

                          int index = touchedSpot.spotIndex;
                          String timeLabel =
                              (index >= 0 && index < labels.length)
                                  ? labels[index]
                                  : "Desconhecido";

                          return LineTooltipItem(
                            '💻$value%\n$timeLabel',
                            TextStyle(
                              color: touchedSpot.bar.gradient?.colors.first ??
                                  touchedSpot.bar.color ??
                                  Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),

                    getTouchedSpotIndicator: (_, indicators) {
                      return indicators.map((index) {
                        return const TouchedSpotIndicatorData(
                          FlLine(color: Colors.transparent),
                          FlDotData(show: true),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
