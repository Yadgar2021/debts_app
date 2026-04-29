import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child; // ئەمە ئەو شتانەیە کە دەکەونە سەر پشتینەکە

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 👈 زیادکردنی ئەم دوو دێڕە بۆ ئەوەی هەمیشە هەموو شاشەکە بگرێتەوە
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        // 👈 دانانی const لێرەدا خێرایی ئەپەکە زیاد دەکات
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(
              255,
              94,
              144,
              180,
            ), // دەتوانیت لێرەدا ڕەنگەکان بگۆڕیت
            Color.fromARGB(255, 197, 136, 136),
          ],
        ),
      ),
      child: child,
    );
  }
}
