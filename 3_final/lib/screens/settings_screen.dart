// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:monitoramentoapp/generals/globals.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _hostController;
  late TextEditingController _maxPointsController;
  late bool _realTime;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: hostIp);
    _maxPointsController = TextEditingController(text: maxPoints.toString());
    _realTime = isRealTime;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _maxPointsController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    setState(() {
      hostIp = _hostController.text;
      maxPoints = int.tryParse(_maxPointsController.text) ?? defaultMaxPoints;
      isRealTime = _realTime;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Configurações salvas.")),
    );
  }

  void _resetSettings() {
    setState(() {
      hostIp = defaultHostIp;
      isRealTime = defaultIsRealTime;
      maxPoints = defaultMaxPoints;

      _hostController.text = hostIp;
      _maxPointsController.text = maxPoints.toString();
      _realTime = isRealTime;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Configurações resetadas.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Endereço IP do RabbitMQ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxPointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Máximo de pontos plotados nos gráficos',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Modo tempo real"),
                Switch(
                  value: _realTime,
                  onChanged: (value) {
                    setState(() {
                      _realTime = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                ),
                ElevatedButton.icon(
                  onPressed: _resetSettings,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Resetar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
