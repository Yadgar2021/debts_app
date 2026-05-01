import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  final String hintText;
  final TextEditingController? controller;

  const CustomSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'گەڕان...',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF4A90E2)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
