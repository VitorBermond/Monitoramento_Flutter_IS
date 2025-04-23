import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CPUUsageScreen(),
    );
  }
}

class CPUUsageScreen extends StatefulWidget {
  const CPUUsageScreen({super.key});

  @override
  State<CPUUsageScreen> createState() => _CPUUsageScreenState();
}

class _CPUUsageScreenState extends State<CPUUsageScreen> {
  List<FlSpot> cpuUsageData = [];
  late Client client;
  double time = 0;

  @override
  void initState() {
    super.initState();
    _connectToRabbitMQ();
  }

  void _connectToRabbitMQ() {
    try {
      client = Client(
        settings: ConnectionSettings(host: "localhost"),
      );

      client.channel().then((Channel channel) {
        return channel.queue("Data.CPU", durable: false);
      }).then((Queue queue) {
        queue.consume().then((Consumer consumer) {
          consumer.listen((AmqpMessage message) {
            final data = jsonDecode(message.payloadAsString);
            double cpuValue = (data['cpu_usage'] as num).toDouble();
            setState(() {
              if (cpuUsageData.length >= 20) {
                cpuUsageData.removeAt(0);
              }
              cpuUsageData.add(FlSpot(time, cpuValue));
              time += 1;
            });
          });
        });
      });
    } catch (e) {
      debugPrint("Erro ao conectar ao RabbitMQ: $e");
    }
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
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: cpuUsageData,
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              cpuUsageData.isNotEmpty
                  ? "Uso da CPU: ${cpuUsageData.last.y.toStringAsFixed(2)}%"
                  : "Aguardando dados...",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
