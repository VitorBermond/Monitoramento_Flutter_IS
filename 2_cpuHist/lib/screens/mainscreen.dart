import 'package:flutter/material.dart';
import 'package:teste7v5/screens/cpu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aplicação de Monitoramento")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Row com três imagens lado a lado
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 100, height: 50),
                Image.asset('assets/images/logo.png', width: 100, height: 50),
                Image.asset('assets/images/logo.png', width: 100, height: 50),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CPUUsageScreen(),
                  ),
                );
              },
              child: const Text("Gráfico"),
            ),
          ],
        ),
      ),
    );
  }
}
