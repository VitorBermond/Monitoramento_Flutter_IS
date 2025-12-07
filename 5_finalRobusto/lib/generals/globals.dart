import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:dart_amqp/dart_amqp.dart';

// Variáveis globais

// Configurações Default
const String defaultHostIp = "localhost";
const bool defaultIsRealTime = true;
const int defaultMaxPoints = 60;

// IP do broker RabbitMQ
String hostIp = defaultHostIp;

// seleção de modo tempo real ou histórico é compartilhado com todas as metricas
bool isRealTime = defaultIsRealTime;

int maxPoints = defaultMaxPoints; // máximo de pontos mostrados nos gráficos

bool isDurable = false; // Configuração de persistência da fila RabbitMQ

// Cores que representam cada chave dos maps. Indo de 0 a 13 (se tiver mais serviços essa lista deve aumentar)
const List<Color> listaCores = [
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFFF44336),
  Color(0xFF8BC34A),
  Color(0xFF3F51B5),
  Color(0xFFF48FB1),
  Color(0xFF00E676),
  Color(0xFF009688),
  Color(0xFFFFC107),
  Color(0xFF4CAF50),
  Color(0xFFF44336),
  Color(0xFF673AB7),
  Color(0xFFFF5722),
  Color(0xFF00BCD4),
  Color(0xFF9C27B0),
];
