import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child; // ئەمە ئەو شتانەیە کە دەکەونە سەر پشتینەکە

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromARGB(
              255,
              94,
              144,
              180,
            ), // دەتوانیت لێرەدا ڕەنگەکان بگۆڕیت
            const Color.fromARGB(255, 197, 136, 136),
          ],
        ),
      ),
      child: child,
    );
  }
}
