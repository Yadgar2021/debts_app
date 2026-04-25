import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final double totalOwedToMe;
  final double totalIOwe;

  const SummaryCard({
    super.key,
    required this.totalOwedToMe,
    required this.totalIOwe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              title: 'لای خەڵکە',
              amount: '\$${totalOwedToMe.toStringAsFixed(2)}',
              color: Colors.green.shade700,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          Container(
            height: 50,
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Expanded(
            child: _buildSummaryItem(
              title: 'لەسەرمە',
              amount: '\$${totalIOwe.toStringAsFixed(2)}',
              color: Colors.red.shade600,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
