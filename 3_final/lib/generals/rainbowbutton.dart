import 'dart:math' as math;
import 'package:flutter/material.dart';

class RainbowButton extends StatefulWidget {
  final String text;
  final Widget destination;

  const RainbowButton({
    super.key,
    required this.text,
    required this.destination,
  });

  @override
  State<RainbowButton> createState() => _RainbowButtonState();
}

class _RainbowButtonState extends State<RainbowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6), // ajuste a velocidade
      vsync: this,
    )..repeat(); // rotação infinita
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// SweepGradient gerando o arco-íris (primeira cor repetida no fim p/ fechar o ciclo)
  SweepGradient _buildGradient(double angle) => SweepGradient(
        tileMode: TileMode.repeated,
        transform: GradientRotation(angle),
        colors: const [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
          Colors.red, // repete para fechar o círculo
        ],
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final shaderAngle = _controller.value * 2 * math.pi; // 0 → 2π
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => widget.destination),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) =>
                _buildGradient(shaderAngle).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

// rainbow config button

Widget buildRainbowAppBarButton({
  required IconData icon,
  required String tooltip,
  required VoidCallback onPressed,
  Duration duration = const Duration(seconds: 6),
}) {
  return _RainbowIconButton(
    icon: icon,
    tooltip: tooltip,
    onPressed: onPressed,
    duration: duration,
  );
}

class _RainbowIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Duration duration;

  const _RainbowIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.duration,
  });

  @override
  State<_RainbowIconButton> createState() => _RainbowIconButtonState();
}

class _RainbowIconButtonState extends State<_RainbowIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  SweepGradient _buildGradient(double angle) => SweepGradient(
        tileMode: TileMode.repeated,
        transform: GradientRotation(angle),
        colors: const [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
          Colors.red, // fecha o ciclo
        ],
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final shaderAngle = _controller.value * 2 * math.pi;
        return IconButton(
          tooltip: widget.tooltip,
          onPressed: widget.onPressed,
          icon: ShaderMask(
            shaderCallback: (bounds) =>
                _buildGradient(shaderAngle).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Icon(widget.icon, size: 26, color: Colors.white),
          ),
        );
      },
    );
  }
}
