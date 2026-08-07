import 'dart:ui';

import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 24,
    this.blur = 18,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.045),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return onTap == null
        ? panel
        : InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: panel,
          );
  }
}
