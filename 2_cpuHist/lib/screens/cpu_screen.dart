import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const int maxPoints = 60;

class CPUUsageData {
  static final CPUUsageData _instance = CPUUsageData._internal();
  factory CPUUsageData() => _instance;
  CPUUsageData._internal();

  final List<FlSpot> cpuDataReal = [];
  final List<FlSpot> cpuDataHist = [];
  final List<String> timeLabelsReal = [];
  final List<String> timeLabelsHist = [];
  double timeIndexReal = 0;
}

class CPUUsageScreen extends StatefulWidget {
  const CPUUsageScreen({super.key});

  @override
  State<CPUUsageScreen> createState() => _CPUUsageScreenState();
}

class _CPUUsageScreenState extends State<CPUUsageScreen> {
  final CPUUsageData dataStore = CPUUsageData();
  late Client client;
  bool isRealTime = true;

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

  void _connectToRabbitMQ() {
    try {
      client = Client(settings: ConnectionSettings(host: "localhost"));
      client.channel().then((Channel channel) {
        return channel.queue("Data.CPU", durable: false);
      }).then((Queue queue) {
        queue.consume().then((Consumer consumer) {
          consumer.listen((AmqpMessage message) {
            final data = jsonDecode(message.payloadAsString);
            double cpuValue = (data['cpu_usage'] as num).toDouble();
            String timestamp = data['timestamp'];
            String formattedTime = DateFormat("HH:mm:ss")
                .format(DateTime.parse(timestamp).toLocal());

            setState(() {
              if (dataStore.cpuDataReal.length >= maxPoints) {
                dataStore.cpuDataReal.removeAt(0);
                dataStore.timeLabelsReal.removeAt(0);
              }
              dataStore.cpuDataReal
                  .add(FlSpot(dataStore.timeIndexReal, cpuValue));
              dataStore.timeLabelsReal.add(formattedTime);
              dataStore.timeIndexReal += 1;
            });
          });
        });
      });
    } catch (e) {
      debugPrint("Erro ao conectar ao RabbitMQ: $e");
    }
  }

  void _listenToHistCPU() {
    client.channel().then((Channel channel) {
      return channel.queue("Hist.CPU", durable: false);
    }).then((Queue queue) {
      queue.consume().then((Consumer consumer) {
        consumer.listen((AmqpMessage message) {
          try {
            final payload = jsonDecode(message.payloadAsString);

            // Verifica se o payload é um Map e contém uma chave 'historico'
            if (payload is Map<String, dynamic> &&
                payload.containsKey('historico')) {
              final data = payload['historico'];

              // Verifica se 'historico' é uma lista
              if (data is List<dynamic>) {
                debugPrint("Dados recebidos: $data");

                setState(() {
                  dataStore.cpuDataHist.clear();
                  dataStore.timeLabelsHist.clear();

                  for (var entry in data) {
                    if (entry is Map<String, dynamic> &&
                        entry["cpu_usage"] != null &&
                        entry["timestamp"] != null &&
                        entry["timeIndex"] != null) {
                      dataStore.cpuDataHist.add(FlSpot(
                        (entry["timeIndex"] as num).toDouble(),
                        (entry["cpu_usage"] as num).toDouble(),
                      ));
                      dataStore.timeLabelsHist.add(entry["timestamp"]);
                    }
                  }
                  isRealTime = false;

                  // Aplica downsampling após carregar os dados históricos
                  _applyDownsampling();
                });
              } else {
                debugPrint(
                    "Erro: O conteúdo da chave 'historico' não é uma lista. Recebido: $data");
              }
            } else {
              debugPrint(
                  "Erro: Payload não contém a chave 'historico' ou não é um Map. Recebido: $payload");
            }
          } catch (e) {
            debugPrint("Erro ao decodificar o payload: $e");
          }
        });
      });
    });
  }

  void _applyDownsampling() {
    if (dataStore.cpuDataHist.length <= maxPoints) return;

    final int step = (dataStore.cpuDataHist.length / maxPoints).ceil();
    final List<FlSpot> downsampledData = [];
    final List<String> downsampledLabels = [];

    for (int i = 0; i < dataStore.cpuDataHist.length; i += step) {
      int end = (i + step < dataStore.cpuDataHist.length)
          ? i + step
          : dataStore.cpuDataHist.length;

      // Calcula a média dos pontos do intervalo atual
      double avgX = 0;
      double avgY = 0;

      for (int j = i; j < end; j++) {
        avgX += dataStore.cpuDataHist[j].x;
        avgY += dataStore.cpuDataHist[j].y;
      }

      int count = end - i;
      avgX /= count;
      avgY /= count;

      downsampledData.add(FlSpot(avgX, avgY));

      // Calcula o índice intermediário para usar o label central do intervalo
      int midpointIndex = (i + end) ~/ 2;
      downsampledLabels.add(dataStore.timeLabelsHist[midpointIndex]);
    }

    setState(() {
      dataStore.cpuDataHist
        ..clear()
        ..addAll(downsampledData);

      dataStore.timeLabelsHist
        ..clear()
        ..addAll(downsampledLabels);
    });
  }

  void _requestHistoricalData() {
    try {
      final now = DateTime.now();

      // Um request vazio resultará numa pesquisa da hora atual (0 a 59 minutos)

      final startYear = int.tryParse(startYearController.text) ?? now.year;
      final startMonth = int.tryParse(startMonthController.text) ?? now.month;
      final startDay = int.tryParse(startDayController.text) ?? now.day;
      final startHour = int.tryParse(startHourController.text) ?? now.hour;
      final startMinute =
          int.tryParse(startMinuteController.text) ?? 0; // Se vazio, minuto é 0

      final endYear = int.tryParse(endYearController.text) ?? now.year;
      final endMonth = int.tryParse(endMonthController.text) ?? now.month;
      final endDay = int.tryParse(endDayController.text) ?? now.day;
      final endHour = int.tryParse(endHourController.text) ?? now.hour;
      final endMinute =
          int.tryParse(endMinuteController.text) ?? 59; // Se vazio, minuto é 59

      final channel = client.channel();
      channel.then((Channel ch) {
        ch.queue("HistRequest.CPU", durable: false).then((Queue queue) {
          final request = jsonEncode({
            "start_year": startYear,
            "start_month": startMonth,
            "start_day": startDay,
            "start_hour": startHour,
            "start_minute": startMinute,
            "end_year": endYear,
            "end_month": endMonth,
            "end_day": endDay,
            "end_hour": endHour,
            "end_minute": endMinute,
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
              mainAxisAlignment: MainAxisAlignment.start,
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
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
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
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _requestHistoricalData,
                    child: const Text("Buscar Histórico"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleMode,
                    child:
                        Text(isRealTime ? "Modo Histórico" : "Modo Tempo Real"),
                  ),
                ),
              ],
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
                        reservedSize: 30,
                        interval: isRealTime
                            ? 5 // No modo Tempo Real, mantém o intervalo fixo como 5
                            : (dataStore.cpuDataHist.isNotEmpty
                                ? (dataStore.cpuDataHist.last.x -
                                        dataStore.cpuDataHist.first.x) /
                                    10
                                : 5), // Modo Histórico, ajusta o intervalo automaticamente
                        getTitlesWidget: (value, meta) {
                          List<String> labels = isRealTime
                              ? dataStore.timeLabelsReal
                              : dataStore.timeLabelsHist;
                          List<FlSpot> data = isRealTime
                              ? dataStore.cpuDataReal
                              : dataStore.cpuDataHist;

                          if (labels.isEmpty || data.isEmpty) {
                            return Container();
                          }

                          // Recalcula o índice com base no primeiro ponto do gráfico
                          // int index = (value - data.first.x).round();
                          int index =
                              (value / (data.last.x / labels.length)).round();

                          // Garante que o índice esteja dentro dos limites
                          if (index < 0 || index >= labels.length) {
                            return Container();
                          }

                          return Text(
                            labels[index],
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black),
                          );
                        },
                      ),
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
                      sideTitles:
                          SideTitles(showTitles: false, reservedSize: 40),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: isRealTime
                          ? dataStore.cpuDataReal
                          : dataStore.cpuDataHist,
                      isCurved: true,
                      curveSmoothness: 0.4,
                      preventCurveOverShooting: true,
                      color: Colors.blue,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  // ANIMACAO DE TOQUE NOS PONTOS DO GRAFICO
                  lineTouchData: LineTouchData(
                    touchSpotThreshold: 10,
                    handleBuiltInTouches: true,
                    // TOOLTIP OU INDICAÇÃO AO TOQUE
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final value = touchedSpot.y.toStringAsFixed(2);

                          // Pega o índice do ponto tocado
                          int index = touchedSpot.spotIndex;

                          // Seleciona a lista apropriada de labels de tempo
                          List<String> labels = isRealTime
                              ? dataStore.timeLabelsReal
                              : dataStore.timeLabelsHist;

                          // Obtém o horário correspondente do ponto tocado
                          String timeLabel =
                              (index >= 0 && index < labels.length)
                                  ? labels[index]
                                  : "Desconhecido";

                          return LineTooltipItem(
                            '💻$value%\n🕒$timeLabel',
                            const TextStyle(
                              color: Colors.lightBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    // REMOVE A LINHA LIGADA AO EIXO X AO TOCAR
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                              color: Colors.transparent,
                              strokeWidth: 0), // Linha invisível (NÃO APARECE)
                          FlDotData(show: true),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
