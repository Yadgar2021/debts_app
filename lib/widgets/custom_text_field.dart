import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        // 👈 ڕەنگێکمان دا بە ئایکۆنەکە بۆ ئەوەی لەگەڵ دوگمەکانی ترت بگونجێت
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF4A90E2)),
        // 👈 ئەم دوو دێڕە وا دەکات بۆکسەکە ڕەنگی سپی بێت، بۆ سەر باکگراوندی ڕەنگاوڕەنگ زۆر جوانە
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          // 👈 بۆ ئەوەی هێڵی دەوروبەری بۆکسەکە زۆر تۆخ نەبێت
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
