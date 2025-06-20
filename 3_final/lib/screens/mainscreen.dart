import 'package:flutter/material.dart';
import 'package:monitoramentoapp/generals/rainbowbutton.dart';
import 'package:monitoramentoapp/screens/custom/customscreen.dart';
import 'package:monitoramentoapp/screens/fps_screen.dart';
import 'package:monitoramentoapp/screens/gpu_screen.dart';
import 'package:monitoramentoapp/screens/ni_screen.dart';
import 'package:monitoramentoapp/screens/settings_screen.dart';
import 'package:monitoramentoapp/screens/cpu_screen.dart';
import 'package:monitoramentoapp/screens/pt_screen.dart';
import 'package:monitoramentoapp/screens/te_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoramento de recursos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/ifes.png', width: 300, height: 100),
                const SizedBox(width: 10),
                Image.asset('assets/images/labsea.png',
                    width: 300, height: 110),
              ],
            ),

            // Wrap e botão CUSTOM agrupados numa coluna
            Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CPUScreen(),
                          ),
                        );
                      },
                      child: const Text("CPU"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GPUScreen(),
                          ),
                        );
                      },
                      child: const Text("GPU"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PTScreen(),
                          ),
                        );
                      },
                      child: const Text("PT"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TEScreen(),
                          ),
                        );
                      },
                      child: const Text("TE"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FPSScreen(),
                          ),
                        );
                      },
                      child: const Text("FPS"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NIScreen(),
                          ),
                        );
                      },
                      child: const Text("NI"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                RainbowButton(
                  text: "CUSTOM",
                  destination: const CUSTOMScreen(),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
