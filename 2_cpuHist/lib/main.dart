//import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:dart_amqp/dart_amqp.dart';
//import 'package:fl_chart/fl_chart.dart';
//import 'package:intl/intl.dart';

import 'package:teste7v5/screens/mainscreen.dart';
//import 'package:teste7v5/screens/cpu_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
