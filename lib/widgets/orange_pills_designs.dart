import 'package:flutter/material.dart';

class OrangePills extends StatefulWidget {
  const OrangePills({super.key});

  @override
  State<OrangePills> createState() => _OrangePillsState();
}

class _OrangePillsState extends State<OrangePills>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // continuous loop
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Colors.orange;

    return Transform.rotate(
      angle: -12 * 3.1415926 / 180,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => _Pill(
              color: Colors.orange.withOpacity(.28),
              width: 64 + (10 * _controller.value), 
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => _Pill(
              color: orange.withOpacity(.34),
              width: 78 + (12 * _controller.value),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => _Pill(
              color: orange,
              width: 86 + (14 * _controller.value),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.width});
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.24),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}