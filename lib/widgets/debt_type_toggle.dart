import 'package:flutter/material.dart';

class DebtTypeToggle extends StatelessWidget {
  final bool isOwedToMe;
  final ValueChanged<bool> onChanged;

  const DebtTypeToggle({
    super.key,
    required this.isOwedToMe,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // 👈 ڕەنگەکەمان کرد بە سپییەکی شەفاف بۆ ئەوەی لەسەر باکگراوندە ڕەنگاوڕەنگەکە جوانتر بێت
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true), // گۆڕینی دۆخەکە بۆ "لای خەڵکە"
              // 👈 گۆڕیمان بۆ AnimatedContainer بۆ ئەوەی جوڵەکەی نەرم بێت
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isOwedToMe ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'لایەتی',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOwedToMe ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false), // گۆڕینی دۆخەکە بۆ "لەسەرمە"
              // 👈 گۆڕیمان بۆ AnimatedContainer بۆ ئەوەی جوڵەکەی نەرم بێت
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isOwedToMe ? Colors.red : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'هەیەتی',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !isOwedToMe ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
