import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dart_amqp/dart_amqp.dart';
import 'dart:convert';

import 'package:monitoramentoapp/generals/date_input.dart';
import 'package:monitoramentoapp/generals/metrics.dart';
import 'package:monitoramentoapp/generals/visibility_buttons.dart';
import 'package:monitoramentoapp/generals/linechart.dart';
import 'package:monitoramentoapp/generals/globals.dart';

class GPUScreen extends StatefulWidget {
  const GPUScreen({super.key});

  @override
  State<GPUScreen> createState() => _GPUScreenState();
}

class _GPUScreenState extends State<GPUScreen> {
  // Cria o DataStore (metrics.dart)
  final gpuDataStore = MetricDataManager.getInstance("GPU");

  /// Variáveis Auxiliares
  static const String titulo = "Monitoramento de uso de GPU";

  // Conexão RabbitMQ
  late Client client;
  static const String realQueue = "Data.GPU";
  static const String histQueue = "Hist.GPU";
  static const String reqHQueue = "HistRequest.GPU";

  // Construção do gráfico
  static const String unit = "%";
  static const double cMinY = 0;
  static const double cMaxY = 100;

  // JSON
  static const String metric = "gpu_usage";
  static const String timestamp = "timestamp";
  static const String servicename = "service_name";

  // Cria os controladores do conjunto de TextFields para inserção da data inicial (date_input.dart)
  final DateTimeControllers startControllers = DateTimeControllers();

  // Cria os controladores do conjunto de TextFields para inserção da data final (date_input.dart)
  final DateTimeControllers endControllers = DateTimeControllers();

  // Cria o Textfield para inserção manual de serviços
  final TextEditingController _manualServiceController =
      TextEditingController();

  // Estado inicial
  @override
  void initState() {
    super.initState();
    _rabbitMQRealTime();
    _rabbitMQHistoric();
  }

  // Ações ao sair da tela
  @override
  void dispose() {
    startControllers.dispose();
    endControllers.dispose();
    _manualServiceController.dispose();

    client.close();
    super.dispose();
  }

  // Conexão RabbitMQ do Modo Tempo Real
  void _rabbitMQRealTime() async {
    try {
      client = Client(settings: ConnectionSettings(host: hostIp));
      final channel = await client.channel();
      final queue = await channel.queue(realQueue, durable: false);

      queue.consume().then((Consumer consumer) {
        consumer.listen((AmqpMessage message) {
          final data = jsonDecode(message.payloadAsString);

          // Tratamento do JSON recebido !!!
          double metricValue = (data[metric] as num).toDouble();
          final String serviceName =
              data[servicename]?.toString().trim().isNotEmpty == true
                  ? data[servicename].toString()
                  : 'APP'; // fallback
          int timestampEpoch =
              (data[timestamp] as num).toInt(); // Ex: 1745927603

          // Transforma Unix Epoch em string formatada
          String formattedTime = DateFormat("📅dd/MM/yy\n🕒HH:mm:ss").format(
            DateTime.fromMillisecondsSinceEpoch(timestampEpoch * 1000)
                .toLocal(),
          );

          // setState dessa forma faz com que o gráfico atualize a cada mensagem recebida
          setState(() {
            // Adiciona o nome à lista de serviços, se ainda não estiver
            if (!gpuDataStore.servicesList.containsValue(serviceName)) {
              int newKey = gpuDataStore.servicesList.length;
              gpuDataStore.servicesList[newKey] = serviceName;
            }

            // Inicializa os mapas, usando serviceName como chave
            gpuDataStore.realData.putIfAbsent(serviceName, () => []);
            gpuDataStore.timeLabelsReal.putIfAbsent(serviceName, () => []);
            gpuDataStore.timeEpochsReal.putIfAbsent(serviceName, () => []);

            // Remove o primeiro ponto se exceder o limite
            if ((gpuDataStore.realData[serviceName]?.length ?? 0) >=
                maxPoints) {
              gpuDataStore.realData[serviceName]?.removeAt(0);
              gpuDataStore.timeLabelsReal[serviceName]?.removeAt(0);
              gpuDataStore.timeEpochsReal[serviceName]?.removeAt(0);
            }

            // Adiciona os dados ao gráfico e aos rótulos
            gpuDataStore.realData[serviceName]!.add(
              FlSpot(gpuDataStore.indexReal.toDouble(), metricValue),
            );
            gpuDataStore.timeLabelsReal[serviceName]!.add(formattedTime);
            gpuDataStore.timeEpochsReal[serviceName]!.add(timestampEpoch);

            // Incrementa o índice global
            gpuDataStore.indexReal++;
          });
        });
      });
    } catch (e) {
      debugPrint("Erro ao conectar ao RabbitMQ: $e");
    }
  }

  // Conexão RabbitMQ Modo Histórico
  void _rabbitMQHistoric() {
    client.channel().then((Channel channel) {
      return channel.queue(histQueue, durable: false);
    }).then((Queue queue) {
      queue.consume().then((Consumer consumer) {
        consumer.listen((AmqpMessage message) {
          try {
            final payload = jsonDecode(message.payloadAsString);

            if (payload is Map<String, dynamic> &&
                payload.containsKey('historico')) {
              final data = payload['historico'];
              final serviceName = payload[servicename]?.toString() ?? '0';

              if (data is List<dynamic>) {
                setState(() {
                  if (!gpuDataStore.servicesList.containsValue(serviceName)) {
                    final newKey = gpuDataStore.servicesList.length;
                    gpuDataStore.servicesList[newKey] = serviceName;
                  }

                  gpuDataStore.histData.putIfAbsent(serviceName, () => []);
                  gpuDataStore.histData[serviceName]?.clear();
                  gpuDataStore.timeLabelsHist
                      .putIfAbsent(serviceName, () => []);
                  gpuDataStore.timeLabelsHist[serviceName]?.clear();
                  gpuDataStore.timeEpochsHist
                      .putIfAbsent(serviceName, () => []);
                  gpuDataStore.timeEpochsHist[serviceName]?.clear();

                  // Nova contagem de índices para Downsampling
                  int timeIndex = 0;

                  for (var entry in data) {
                    if (entry is Map<String, dynamic> &&
                        entry[metric] != null &&
                        entry[timestamp] != null) {
                      gpuDataStore.histData[serviceName]!.add(FlSpot(
                        timeIndex.toDouble(),
                        (entry[metric] as num).toDouble(),
                      ));

                      int timestampEpoch = (entry["timestamp"] as num).toInt();
                      String formattedTime =
                          DateFormat("📅dd/MM/yy\n🕒HH:mm:ss").format(
                        DateTime.fromMillisecondsSinceEpoch(
                                timestampEpoch * 1000)
                            .toLocal(),
                      );

                      gpuDataStore.timeLabelsHist[serviceName]!
                          .add(formattedTime);
                      gpuDataStore.timeEpochsHist[serviceName]!
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
              debugPrint(
                  "Erro: Payload inválido em $histQueue. Recebido: $payload");
            }
          } catch (e) {
            debugPrint("Erro ao decodificar payload de $histQueue: $e");
          }
        });
      });
    });
  }

  // Aplica Downsampling para os dados recebidos da fila de histórico
  void _applyDownsampling(String serviceName) {
    if (!gpuDataStore.histData.containsKey(serviceName) ||
        gpuDataStore.histData[serviceName]!.length <= maxPoints) {
      return;
    }

    final List<FlSpot> originalData = gpuDataStore.histData[serviceName]!;
    final List<String> originalLabels =
        gpuDataStore.timeLabelsHist[serviceName] ?? [];
    final List<int> originalEpochs =
        gpuDataStore.timeEpochsHist[serviceName] ?? [];

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

    gpuDataStore.histData[serviceName] = downsampledData;
    gpuDataStore.timeLabelsHist[serviceName] = downsampledLabels;
    gpuDataStore.timeEpochsHist[serviceName] = downsampledEpochs;
  }

  // Envia uma requisição de histórico
  void _requestHistoricalData() {
    try {
      final now = DateTime.now();

      // Constrói o DateTime inicial considerando os valores inseridos e se for vazio utiliza a hora atual
      final start = DateTime(
        int.tryParse(startControllers.year.text) ?? now.year,
        int.tryParse(startControllers.month.text) ?? now.month,
        int.tryParse(startControllers.day.text) ?? now.day,
        int.tryParse(startControllers.hour.text) ?? now.hour,
        int.tryParse(startControllers.minute.text) ?? 0,
      ).subtract(Duration(hours: 0));

      // Constrói o DateTime final considerando os valores inseridos e se for vazio utiliza a hora atual
      final end = DateTime(
        int.tryParse(endControllers.year.text) ?? now.year,
        int.tryParse(endControllers.month.text) ?? now.month,
        int.tryParse(endControllers.day.text) ?? now.day,
        int.tryParse(endControllers.hour.text) ?? now.hour,
        int.tryParse(endControllers.minute.text) ?? 59,
      ).subtract(Duration(hours: 0));

      // Converte para timestamps em segundos (Unix epoch)
      final int startTimestamp = start.toUtc().millisecondsSinceEpoch ~/ 1000;
      final int endTimestamp = end.toUtc().millisecondsSinceEpoch ~/ 1000;

      final channel = client.channel();
      channel.then((Channel ch) {
        ch.queue(reqHQueue, durable: false).then((Queue queue) {
          final request = jsonEncode({
            // Constroi o JSON da requisição
            "start_datetime": startTimestamp,
            "end_datetime": endTimestamp,
            "services_list": gpuDataStore.servicesList.values.toList(),
          });
          queue.publish(request);
          debugPrint("Requisição enviada com sucesso: $request");
        });
      });
    } catch (e) {
      debugPrint("Erro ao enviar requisição de histórico: $e");
    }
  }

  // Ação do botão de mudar modo
  void _toggleMode() {
    setState(() {
      isRealTime = !isRealTime;
    });
  }

  // ação do botão de adicionar serviços manualmente
  void _addManualService() {
    final name = _manualServiceController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      // adiciona na lista se ainda não existir
      if (!gpuDataStore.servicesList.containsValue(name)) {
        final newKey = gpuDataStore.servicesList.length;
        gpuDataStore.servicesList[newKey] = name;
      }

      // garante que todos os mapas já existam (tratamento não nulo)
      gpuDataStore.realData.putIfAbsent(name, () => []);
      gpuDataStore.timeLabelsReal.putIfAbsent(name, () => []);
      gpuDataStore.timeEpochsReal.putIfAbsent(name, () => []);
      gpuDataStore.histData.putIfAbsent(name, () => []);
      gpuDataStore.timeLabelsHist.putIfAbsent(name, () => []);
      gpuDataStore.timeEpochsHist.putIfAbsent(name, () => []);
    });

    _manualServiceController.clear();
  }

  // Construção da tela
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(titulo),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Resetar dados',
            onPressed: () {
              gpuDataStore.reset();
              setState(() {});
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cria os Widgets para inserção de data Inicial
                  DateTimeInputRow(
                    labelPrefix: "Inicial",
                    controllers: startControllers,
                  ),
                  const SizedBox(height: 10),
                  // Cria os Widgets para inserção de data Final
                  DateTimeInputRow(
                    labelPrefix: "Final",
                    controllers: endControllers,
                  ),
                ],
              ),
              const SizedBox(width: 5),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _toggleMode,
                    child:
                        Text(isRealTime ? "Modo Histórico" : "Modo Tempo Real"),
                  ),
                ),
                SizedBox(height: 25),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _requestHistoricalData,
                    child: const Text("Buscar Histórico"),
                  ),
                ),
              ]),
              SizedBox(width: 5),

              // Campo + botão para adicionar serviço manualmente
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _addManualService,
                      child: const Text('Adicionar serviço'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _manualServiceController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nome do serviço',
                      ),
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 5),

            // Cria os botões de visibilidade (visibility_buttons.dart)
            ServiceVisibilityButtons(
              dataStore: gpuDataStore,
              onVisibilityToggled: () => setState(() {}),
            ),

            const SizedBox(height: 5),

            // Gráfico de linha (linechart.dart)
            MetricChart(
              dataStore: gpuDataStore,
              unitSuffix: unit,
              minY: cMinY,
              maxY: cMaxY,
            ),
          ],
        ),
      ),
    );
  }
}
