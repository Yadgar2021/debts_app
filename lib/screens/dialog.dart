import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonAccountDialogs {
  // ١. دیالۆگی دەستکاریکردنی وەسڵ
  static Future<void> showEditTransactionDialog(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    final amountController = TextEditingController(
      text: (data['amount'] ?? 0).toDouble().toString(),
    );
    final noteController = TextEditingController(text: data['note'] ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('دەستکاریکردنی وەسڵ'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'بڕی قەرز',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'تکایە بڕی قەرز بنووسە'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'تێبینی',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'پاشگەزبوونەوە',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final parsedAmount =
                      double.tryParse(amountController.text.trim()) ?? 0.0;

                  try {
                    await FirebaseFirestore.instance
                        .collection('debts')
                        .doc(doc.id)
                        .update({
                          'amount': parsedAmount,
                          'note': noteController.text.trim(),
                        });
                    if (context.mounted) {
                      Navigator.pop(context); // تەنها یەک جار پێویستە
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('هەڵەیەک ڕوویدا: $e')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
              ),
              child: const Text(
                'هەڵگرتن',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ٢. دیالۆگی سڕینەوەی وەسڵ
  static Future<bool?> showDeleteDialog(
    BuildContext context,
    String docId,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'سڕینەوەی وەسڵ',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'ئایا دڵنیایت لە سڕینەوەی ئەم وەسڵە؟\nئەم کارە پاشگەزبوونەوەی تێدا نییە.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('نەخێر', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('debts')
                      .doc(docId)
                      .delete();
                  if (context.mounted) {
                    Navigator.pop(context, true); // سڕایەوە بە سەرکەوتوویی
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('نەتوانرا بسڕێتەوە: $e')),
                    );
                    Navigator.pop(context, false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'بەڵێ، بیسڕەوە',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ٣. دیالۆگی پاکتاوکردن (ئەرشیفکردن)
  static Future<void> showArchiveDialog(
    BuildContext context,
    List<dynamic> transactions,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'پاکتاوکردنی حساب',
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'ئایا دڵنیایت دەتەوێت حسابی ئەم کەسە پاکتاو بکەیت؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('نەخێر', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final batch = FirebaseFirestore.instance.batch();
                  for (var doc in transactions) {
                    batch.update(
                      FirebaseFirestore.instance
                          .collection('debts')
                          .doc(doc.id),
                      {'isArchived': true},
                    );
                  }
                  await batch.commit();
                  if (context.mounted) {
                    Navigator.pop(context); // تەنها یەک جار پێویستە
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('هەڵەیەک ڕوویدا لە پاکتاوکردن: $e'),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text(
                'بەڵێ، پاکتاوی بکە',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ٤. دیالۆگی زیادکردنی مامەڵەی نوێ
  static Future<void> showAddTransactionDialog(
    BuildContext context,
    String personName,
    bool isOwedToMe,
  ) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            isOwedToMe ? 'پێدانی قەرز' : 'وەرگرتنەوەی پارە',
            style: TextStyle(color: isOwedToMe ? Colors.red : Colors.green),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'بڕی پارە',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'تکایە بڕەکە بنووسە' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'تێبینی',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'پاشگەزبوونەوە',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final parsedAmount =
                      double.tryParse(amountController.text.trim()) ?? 0.0;

                  try {
                    await FirebaseFirestore.instance.collection('debts').add({
                      'name': personName,
                      'amount': parsedAmount,
                      'isOwedToMe': isOwedToMe,
                      'date': FieldValue.serverTimestamp(),
                      'createdAt': FieldValue.serverTimestamp(),
                      'currency': 'USD',
                      'note': noteController.text.trim(),
                      'isArchived': false,
                    });
                    if (context.mounted) {
                      Navigator.pop(
                        context,
                        true,
                      ); // دەنێرێتەوە بە true بۆ نوێبوونەوە
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('هەڵەیەک ڕوویدا لە تۆمارکردن: $e'),
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isOwedToMe ? Colors.redAccent : Colors.green,
              ),
              child: const Text(
                'تۆمارکردن',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
