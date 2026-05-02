import 'package:flutter/material.dart';
// ئەو فایلە نوێیەی دروستمان کرد لێرەدا بانگی دەکەین
import 'debt_details_sheet.dart';

class DebtListItem extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const DebtListItem({super.key, required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'بێناو';
    final amount = (data['amount'] ?? 0).toDouble();
    final isOwedToMe = data['isOwedToMe'] ?? true;

    // 👈 هێنانەوەی جۆری دراوەکە لە داتابەیس
    final currency = data['currency'] ?? 'USD';
    final currencySymbol = currency == 'USD' ? '\$' : currency;

    // 👈 لێرەدا Dismissible مان بە تەواوی لابرد
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.white.withOpacity(0.8),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: isOwedToMe
                ? Colors.green.shade100
                : Colors.red.shade100,
            child: Icon(
              isOwedToMe ? Icons.arrow_upward : Icons.arrow_downward,
              color: isOwedToMe ? Colors.green : Colors.red,
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            isOwedToMe ? 'پێم داوە' : 'لێم وەرگرتووە',
            style: TextStyle(
              color: isOwedToMe ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
          trailing: Text(
            // 👈 لێرەدا هێمای دراوە ڕاستەقینەکە بەکاردەهێنین
            '$currencySymbol${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          onTap: () {
            // کاتێک کرتەی لێ دەکەیت دەچێتە ناو پەڕەی حسابەکە
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              builder: (context) => DebtDetailsSheet(docId: docId, data: data),
            );
          },
        ),
      ),
    );
  }
}
