import 'package:flutter/material.dart';
import 'package:monitoramentoapp/generals/rainbowbutton.dart';
import 'package:monitoramentoapp/screens/custom/customscreen.dart';
import 'package:monitoramentoapp/screens/custom/customconfig.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoramento de recursos"),
        actions: [
          buildRainbowAppBarButton(
            icon: Icons.settings,
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/ifes.png',
                        width: 300, height: 100),
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
                        RainbowButton(
                          text: "CUSTOM",
                          destination: const CUSTOMScreen(),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // --- Assinatura no canto inferior direito com imagem arredondada ---
          Positioned(
            bottom: 12,
            right: 12,
            child: Opacity(
              opacity: 0.8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'By VitorBermond',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ClipOval(
                    child: Image.asset(
                      'assets/images/grovyle.png',
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
