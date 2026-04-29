import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debts_app/screens/add_debt_screen.dart';

class DebtDetailsSheet extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const DebtDetailsSheet({super.key, required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'بێناو';
    final amount = (data['amount'] ?? 0).toDouble();
    final isOwedToMe = data['isOwedToMe'] ?? true;
    final timestamp = data['date'] as Timestamp?;
    final date = timestamp != null ? timestamp.toDate() : DateTime.now();
    final dateString =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final note = data['note'] ?? '';

    // 👈 لێرەدا دراوەکە لە داتابەیس دەهێنین، ئەگەر نەبوو دەیکەین بە دۆلار
    final currency = data['currency'] ?? 'USD';
    final currencySymbol = currency == 'USD' ? '\$' : currency;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // هێڵە خۆلەمێشییەکەی سەرەوەی بۆتۆم شیتەکە
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  tooltip: "گۆڕانکاری",
                  icon: const Icon(
                    Icons.edit_document,
                    color: Color(0xFF4A90E2),
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddDebtScreen(debtId: docId, existingData: data),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'بڕی پارە:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  // 👈 لێرەدا هێمای دراوە دروستەکە نیشان دەدەین لەبری دۆلاری جێگیر
                  '$currencySymbol${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isOwedToMe ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'بەروار:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  dateString,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            const Text(
              'تێبینی:',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              note.isEmpty ? 'هیچ تێبینییەک نەنووسراوە' : note,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
