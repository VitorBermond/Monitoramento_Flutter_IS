import 'package:flutter/material.dart';
import 'package:monitoramentoapp/generals/globals.dart';

// Variáveis globais

// --------------------- NOVAS CONFIGURAÇÕES DO GRÁFICO -------------------------
String unidade = 'X';
double? customMinY; // null = sem limite
double? customMaxY; // null = sem limite

// ------------------- NOVAS CONFIGURAÇÕES DO RABBITMQ --------------------------
String filaTempoReal = 'Data.Custom';
String filaHistorico = 'Hist.Custom';
String filaRequisitarHistorico = 'HistRequest.Custom';

// ------------------ NOVAS CONFIGURAÇÕES DO JSON (tempo real) ------------------
String campoMetrica1 = 'metric';
String? campoMetrica2 = null;
String? campoMetrica3 = null;

String campoTimestamp1 = 'timestamp';
String? campoTimestamp2 = null;
String? campoTimestamp3 = null;

String campoServiceName1 = 'service_name';
String? campoServiceName2 = null;
String? campoServiceName3 = null;

// -------------------------- VALORES PADRÕES -----------------------------------
const String defaultUnidade = 'X';
const double? defaultcustomMinY = null;
const double? defaultcustomMaxY = null;

const String defaultFilaTempoReal = 'Data.Custom';
const String defaultFilaHistorico = 'Hist.Custom';
const String defaultFilaRequisitarHistorico = 'HistRequest.Custom';

const String defaultCampoMetrica = 'metric';
const String defaultCampoTimestamp = 'timestamp';
const String defaultCampoServiceName = 'service_name';

// Estado e construção da tela

class CustomSettingsScreen extends StatefulWidget {
  const CustomSettingsScreen({super.key});

  @override
  State<CustomSettingsScreen> createState() => _CustomSettingsScreenState();
}

class _CustomSettingsScreenState extends State<CustomSettingsScreen> {
  late TextEditingController _hostController;
  late TextEditingController _maxPointsController;

  late TextEditingController _unidadeController;
  late TextEditingController _customMinYController;
  late TextEditingController _customMaxYController;

  late TextEditingController _filaTempoRealController;
  late TextEditingController _filaHistoricoController;
  late TextEditingController _filaReqHistoricoController;

  late TextEditingController _campoMetricaController1;
  late TextEditingController _campoMetricaController2;
  late TextEditingController _campoMetricaController3;

  late TextEditingController _campoTimestampController1;
  late TextEditingController _campoTimestampController2;
  late TextEditingController _campoTimestampController3;

  late TextEditingController _campoServiceController1;
  late TextEditingController _campoServiceController2;
  late TextEditingController _campoServiceController3;

  late bool _realTime;

  @override
  void initState() {
    super.initState();

    _hostController = TextEditingController(text: hostIp);
    _maxPointsController = TextEditingController(text: maxPoints.toString());
    _realTime = isRealTime;

    _unidadeController = TextEditingController(text: unidade);
    _customMinYController =
        TextEditingController(text: customMinY?.toString() ?? '');
    _customMaxYController =
        TextEditingController(text: customMaxY?.toString() ?? '');

    _filaTempoRealController = TextEditingController(text: filaTempoReal);
    _filaHistoricoController = TextEditingController(text: filaHistorico);
    _filaReqHistoricoController =
        TextEditingController(text: filaRequisitarHistorico);

    _campoMetricaController1 = TextEditingController(text: campoMetrica1);
    _campoMetricaController2 = TextEditingController(text: campoMetrica2);
    _campoMetricaController3 = TextEditingController(text: campoMetrica3);

    _campoTimestampController1 = TextEditingController(text: campoTimestamp1);
    _campoTimestampController2 = TextEditingController(text: campoTimestamp2);
    _campoTimestampController3 = TextEditingController(text: campoTimestamp3);

    _campoServiceController1 = TextEditingController(text: campoServiceName1);
    _campoServiceController2 = TextEditingController(text: campoServiceName2);
    _campoServiceController3 = TextEditingController(text: campoServiceName3);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _maxPointsController.dispose();
    _unidadeController.dispose();
    _customMinYController.dispose();
    _customMaxYController.dispose();
    _filaTempoRealController.dispose();
    _filaHistoricoController.dispose();
    _filaReqHistoricoController.dispose();
    _campoMetricaController1.dispose();
    _campoMetricaController2.dispose();
    _campoMetricaController3.dispose();
    _campoTimestampController1.dispose();
    _campoTimestampController2.dispose();
    _campoTimestampController3.dispose();
    _campoServiceController1.dispose();
    _campoServiceController2.dispose();
    _campoServiceController3.dispose();
    super.dispose();
  }

  // ---------------------------- SALVAR ----------------------------------------
  void _saveSettings() {
    setState(() {
      hostIp = _hostController.text;
      maxPoints = int.tryParse(_maxPointsController.text) ?? defaultMaxPoints;
      isRealTime = _realTime;

      // novos: gráfico
      unidade = _unidadeController.text.trim();
      customMinY = _customMinYController.text.trim().isEmpty
          ? null
          : double.tryParse(_customMinYController.text);
      customMaxY = _customMaxYController.text.trim().isEmpty
          ? null
          : double.tryParse(_customMaxYController.text);

      // novos: RabbitMQ
      filaTempoReal = _filaTempoRealController.text.trim();
      filaHistorico = _filaHistoricoController.text.trim();
      filaRequisitarHistorico = _filaReqHistoricoController.text.trim();

      // novos: JSON
      campoMetrica1 = _campoMetricaController1.text.trim();
      campoMetrica2 = _campoMetricaController2.text.trim();
      campoMetrica3 = _campoMetricaController3.text.trim();

      campoTimestamp1 = _campoTimestampController1.text.trim();
      campoTimestamp2 = _campoTimestampController2.text.trim();
      campoTimestamp3 = _campoTimestampController3.text.trim();

      campoServiceName1 = _campoServiceController1.text.trim();
      campoServiceName2 = _campoServiceController2.text.trim();
      campoServiceName3 = _campoServiceController3.text.trim();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Configurações salvas.")),
    );
  }

  // ---------------------------- RESETAR ---------------------------------------
  void _resetSettings() {
    setState(() {
      // existentes
      hostIp = defaultHostIp;
      isRealTime = defaultIsRealTime;
      maxPoints = defaultMaxPoints;

      // novos: gráfico
      unidade = defaultUnidade;
      customMinY = defaultcustomMinY;
      customMaxY = defaultcustomMaxY;

      // novos: RabbitMQ
      filaTempoReal = defaultFilaTempoReal;
      filaHistorico = defaultFilaHistorico;
      filaRequisitarHistorico = defaultFilaRequisitarHistorico;

      // novos: JSON
      campoMetrica1 = defaultCampoMetrica;
      campoMetrica2 = null;
      campoMetrica3 = null;

      campoTimestamp1 = defaultCampoTimestamp;
      campoTimestamp2 = null;
      campoTimestamp3 = null;

      campoServiceName1 = defaultCampoServiceName;
      campoServiceName2 = null;
      campoServiceName3 = null;

      // atualiza campos visuais
      _hostController.text = hostIp;
      _maxPointsController.text = maxPoints.toString();

      _unidadeController.text = unidade;
      _customMinYController.text = '';
      _customMaxYController.text = '';

      _filaTempoRealController.text = filaTempoReal;
      _filaHistoricoController.text = filaHistorico;
      _filaReqHistoricoController.text = filaRequisitarHistorico;

      _campoMetricaController1.text = campoMetrica1;
      _campoMetricaController2.text = campoMetrica2!;
      _campoMetricaController3.text = campoMetrica3!;

      _campoTimestampController1.text = campoTimestamp1;
      _campoTimestampController2.text = campoTimestamp2!;
      _campoTimestampController3.text = campoTimestamp3!;

      _campoServiceController1.text = campoServiceName1;
      _campoServiceController2.text = campoServiceName2!;
      _campoServiceController3.text = campoServiceName3!;

      _realTime = isRealTime;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Configurações resetadas.")),
    );
  }

  // ---------------------------- UI -------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Nessa tela você pode configurar o gráfico e monitorar o dado que desejar através de filas RabbitMQ!\n"
                "O algoritmo trata cada JSON recebido como um ponto no gráfico, sendo o eixo X o timestamp e o eixo Y o valor da métrica.\n"
                "Cada \"service_name\" diferente cria uma linha no gráfico, porém esse campo é opcional.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // ----------------------- RABBITMQ HOST/IP -------------------------
            _sectionTitle('Servidor RabbitMQ'),
            _textfield(_hostController, 'Endereço IP do RabbitMQ'),

            const SizedBox(height: 12),
            _textfield(
              _maxPointsController,
              'Máximo de pontos plotados nos gráficos',
              keyboardType: TextInputType.number,
            ),

            const Divider(height: 32),
            _sectionTitle('Modo de Exibição'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tempo real"),
                Switch(
                  value: _realTime,
                  onChanged: (v) => setState(() => _realTime = v),
                ),
              ],
            ),
            const Divider(height: 32),
            _sectionTitle('Configuração da fila RabbitMQ'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Fila Durável"),
                Switch(
                  value: isDurable,
                  onChanged: (v) => setState(() => isDurable = v),
                ),
              ],
            ),

            const Divider(height: 32),
            _sectionTitle('Configurações do Gráfico'),
            _textfield(_unidadeController, 'Unidade (eixo Y)'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _textfield(
                    _customMinYController,
                    'customMinY (vazio = auto)',
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _textfield(
                    _customMaxYController,
                    'customMaxY (vazio = auto)',
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),

            const Divider(height: 32),
            _sectionTitle('Filas RabbitMQ'),
            _textfield(_filaTempoRealController, 'Fila tempo real'),
            const SizedBox(height: 12),
            _textfield(_filaHistoricoController, 'Fila histórico'),
            const SizedBox(height: 12),
            _textfield(
                _filaReqHistoricoController, 'Fila requisitar histórico'),

            const Divider(height: 32),
            _sectionTitle('Campos no JSON (tempo real)'),

            /// Linha: 3 campos para a métrica (níveis 1..3)
            Row(
              children: [
                Expanded(
                    child: _textfield(
                        _campoMetricaController1, 'Campo métrica 1')),
                const SizedBox(width: 8),
                Expanded(
                    child: _textfield(
                        _campoMetricaController2, 'Campo métrica 2')),
                const SizedBox(width: 8),
                Expanded(
                    child: _textfield(
                        _campoMetricaController3, 'Campo métrica 3')),
              ],
            ),
            const SizedBox(height: 12),

            /// Linha: 3 campos para o timestamp (níveis 1..3)
            Row(
              children: [
                Expanded(
                    child: _textfield(
                        _campoTimestampController1, 'Campo timestamp 1')),
                const SizedBox(width: 8),
                Expanded(
                    child: _textfield(
                        _campoTimestampController2, 'Campo timestamp 2')),
                const SizedBox(width: 8),
                Expanded(
                    child: _textfield(
                        _campoTimestampController3, 'Campo timestamp 3')),
              ],
            ),
            const SizedBox(height: 12),

            /// Linha: 3 campos para service_name (níveis 1..3)
            Row(
              children: [
                Expanded(
                    child: _textfield(
                        _campoServiceController1, 'Campo service_name 1')),
                const SizedBox(width: 8),
                Expanded(
                    child: _textfield(
                        _campoServiceController2, 'Campo service_name 2')),
                const SizedBox(width: 8),
                Expanded(
                    child: _textfield(
                        _campoServiceController3, 'Campo service_name 3')),
              ],
            ),

            const SizedBox(height: 32),

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

  // ---------- Helpers p/ diminuir repetição ----------------------------------
  Widget _textfield(TextEditingController c, String label,
          {TextInputType keyboardType = TextInputType.text}) =>
      TextField(
        controller: c,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );

  Widget _sectionTitle(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.bold)),
        ),
      );
}
