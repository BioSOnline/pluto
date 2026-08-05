import 'package:flutter/material.dart';

import '../theme/pluto_theme.dart';

class PlutoScreenBackground extends StatelessWidget {
  const PlutoScreenBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [plutoBackground, Color(0xFFF6F8FB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}
