import '../notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'notification_servi ce.dart';// دڵنیابە لەوەی ئەمە لێرەدایە

class PersonAccountDialogs {
  // ١. دیالۆگی دەستکاریکردنی وەسڵ
  static Future<void> showEditTransactionDialog(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>;

    final currentAmount = (data['amount'] ?? 0).toDouble();
    final amountString = currentAmount == currentAmount.toInt()
        ? currentAmount.toInt().toString()
        : currentAmount.toString();

    final amountController = TextEditingController(text: amountString);
    final noteController = TextEditingController(text: data['note'] ?? '');
    final formKey = GlobalKey<FormState>();

    final timestamp = data['dueDate'] as Timestamp?;
    DateTime? selectedDueDate = timestamp?.toDate();
    final personName = data['name'] ?? 'کەسێک';
    final isOwedToMe = data['isOwedToMe'] ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
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
                      decoration: InputDecoration(
                        labelText: 'بڕی قەرز',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'تکایە بڕی قەرز بنووسە'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'تێبینی',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          helpText: 'کاتی گەڕاندنەوە دیاری بکە',
                          cancelText: 'پاشگەزبوونەوە',
                          confirmText: 'هەڵبژاردن',
                        );
                        if (picked != null && picked != selectedDueDate) {
                          setState(() {
                            selectedDueDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedDueDate == null
                                  ? 'کاتی گەڕاندنەوە (ئارەزوومەندانە)'
                                  : 'گەڕاندنەوە: ${selectedDueDate!.year}/${selectedDueDate!.month}/${selectedDueDate!.day}',
                              style: TextStyle(
                                color: selectedDueDate == null
                                    ? Colors.grey.shade700
                                    : Colors.black87,
                                fontWeight: selectedDueDate != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (selectedDueDate != null)
                              InkWell(
                                onTap: () =>
                                    setState(() => selectedDueDate = null),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
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
                              'dueDate': selectedDueDate != null
                                  ? Timestamp.fromDate(selectedDueDate!)
                                  : FieldValue.delete(),
                            });

                        // ڕێکخستنی نۆتیفیکەیشن لە کاتی دەستکاریکردندا
                        if (selectedDueDate != null) {
                          final scheduleTime = DateTime(
                            selectedDueDate!.year,
                            selectedDueDate!.month,
                            selectedDueDate!.day,
                            9,
                            0, // کاتژمێر ٩ی بەیانی
                          );

                          if (scheduleTime.isAfter(DateTime.now())) {
                            await NotificationService().scheduleNotification(
                              id: doc.id.hashCode,
                              title: isOwedToMe
                                  ? 'کاتی وەرگرتنەوەی پارە'
                                  : 'کاتی دانەوەی قەرز',
                              body: isOwedToMe
                                  ? 'کاتی وەرگرتنەوەی قەرزەکەی $personName هاتووە بە بڕی $parsedAmount.'
                                  : 'کاتی دانەوەی قەرزەکەی $personName هاتووە بە بڕی $parsedAmount.',
                              scheduledDate: scheduleTime,
                            );
                          }
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'هەڵگرتن',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
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
                  if (context.mounted) Navigator.pop(context, true);
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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

  // ٣. دیالۆگی پاکتاوکردن
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
                  if (context.mounted) Navigator.pop(context);
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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

    DateTime? selectedDueDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                isOwedToMe ? 'پێدانی قەرز' : 'وەرگرتنەوەی پارە',
                style: TextStyle(
                  color: isOwedToMe ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
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
                      decoration: InputDecoration(
                        labelText: 'بڕی پارە',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'تکایە بڕەکە بنووسە'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'تێبینی',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          helpText: 'کاتی گەڕاندنەوە دیاری بکە',
                          cancelText: 'پاشگەزبوونەوە',
                          confirmText: 'هەڵبژاردن',
                        );
                        if (picked != null && picked != selectedDueDate) {
                          setState(() {
                            selectedDueDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: isOwedToMe
                                  ? Colors.red.shade400
                                  : Colors.green.shade400,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedDueDate == null
                                  ? 'کاتی گەڕاندنەوە (ئارەزوومەندانە)'
                                  : 'گەڕاندنەوە: ${selectedDueDate!.year}/${selectedDueDate!.month}/${selectedDueDate!.day}',
                              style: TextStyle(
                                color: selectedDueDate == null
                                    ? Colors.grey.shade700
                                    : Colors.black87,
                                fontWeight: selectedDueDate != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (selectedDueDate != null)
                              InkWell(
                                onTap: () =>
                                    setState(() => selectedDueDate = null),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
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
                        // ١. تۆمارکردن لە داتابەیس و وەرگرتنی ئایدییەکەی
                        final docRef = await FirebaseFirestore.instance
                            .collection('debts')
                            .add({
                              'name': personName,
                              'amount': parsedAmount,
                              'isOwedToMe': isOwedToMe,
                              'date': FieldValue.serverTimestamp(),
                              'createdAt': FieldValue.serverTimestamp(),
                              'dueDate': selectedDueDate != null
                                  ? Timestamp.fromDate(selectedDueDate!)
                                  : null,
                              'currency': 'USD',
                              'note': noteController.text.trim(),
                              'isArchived': false,
                            });

                        // ٢. دانانی نۆتیفیکەیشن ئەگەر بەروار هەڵبژێردرابوو
                        if (selectedDueDate != null) {
                          final scheduleTime = DateTime(
                            selectedDueDate!.year,
                            selectedDueDate!.month,
                            selectedDueDate!.day,
                            9,
                            0, // نۆتیفیکەیشن لە کاتژمێر ٩ی بەیانی دێت
                          );

                          // تەنها ئەگەر کاتەکە تێنەپەڕیبوو
                          if (scheduleTime.isAfter(DateTime.now())) {
                            await NotificationService().scheduleNotification(
                              id: docRef
                                  .id
                                  .hashCode, // ئایدییەکی ناوازە بەپێی وەسڵەکە
                              title: isOwedToMe
                                  ? 'کاتی وەرگرتنەوەی پارە'
                                  : 'کاتی دانەوەی قەرز',
                              body: isOwedToMe
                                  ? 'کاتی وەرگرتنەوەی قەرزەکەی $personName هاتووە بە بڕی $parsedAmount.'
                                  : 'کاتی دانەوەی قەرزەکەی $personName هاتووە بە بڕی $parsedAmount.',
                              scheduledDate: scheduleTime,
                            );
                          }
                        }

                        if (context.mounted) {
                          Navigator.pop(context, true);
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
                    backgroundColor: isOwedToMe
                        ? Colors.redAccent
                        : Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'تۆمارکردن',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
