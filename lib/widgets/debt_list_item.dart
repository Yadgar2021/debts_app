import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ئەو فایلە نوێیەی دروستمان کرد لێرەدا بانگی دەکەین
import 'package:debts_app/widgets/debt_details_sheet.dart';

class DebtListItem extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const DebtListItem({super.key, required this.docId, required this.data});

  Future<bool?> _showConfirmDeleteDialog(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دڵنیای لە سڕینەوە؟', textAlign: TextAlign.right),
        content: Text(
          'ئایا دڵنیای دەتەوێت قەرزی "$name" بە یەکجاری بسڕیتەوە؟',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('نەخێر', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'بەڵێ، بسڕەوە',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'بێناو';
    final amount = (data['amount'] ?? 0).toDouble();
    final isOwedToMe = data['isOwedToMe'] ?? true;

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showConfirmDeleteDialog(context, name);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) async {
        await FirebaseFirestore.instance
            .collection('debts')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('قەرزی "$name" سڕدرایەوە'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
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
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onTap: () {
              // سەیرکە چەند کورت بووەتەوە! تەنها فایلە نوێیەکە بانگ دەکەین
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                builder: (context) =>
                    DebtDetailsSheet(docId: docId, data: data),
              );
            },
          ),
        ),
      ),
    );
  }
}
