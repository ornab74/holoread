import 'dart:math' as math;

import 'package:flutter/material.dart';

class HolographicBackground extends StatefulWidget {
  const HolographicBackground({
    required this.child,
    required this.animate,
    super.key,
  });

  final Widget child;
  final bool animate;

  @override
  State<HolographicBackground> createState() => _HolographicBackgroundState();
}

class _HolographicBackgroundState extends State<HolographicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant HolographicBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _HoloPainter(_controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _HoloPainter extends CustomPainter {
  _HoloPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF050814),
          Color(0xFF0C1025),
          Color(0xFF07121F),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final centers = <Offset>[
      Offset(
        size.width * (0.18 + 0.05 * math.sin(t * math.pi * 2)),
        size.height * 0.22,
      ),
      Offset(
        size.width * 0.82,
        size.height * (0.32 + 0.07 * math.cos(t * math.pi * 2)),
      ),
      Offset(size.width * 0.5, size.height * 0.88),
    ];
    final colors = <Color>[
      const Color(0xFF7B61FF),
      const Color(0xFF19D3FF),
      const Color(0xFFFF4FD8),
    ];
    for (var i = 0; i < centers.length; i++) {
      final radius = math.max(size.width, size.height) * 0.38;
      final glow = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            colors[i].withValues(alpha: 0.19),
            colors[i].withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centers[i], radius: radius));
      canvas.drawCircle(centers[i], radius, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _HoloPainter oldDelegate) => oldDelegate.t != t;
}
