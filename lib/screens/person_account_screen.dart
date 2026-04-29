import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/gradient_background.dart';

class PersonAccountScreen extends StatelessWidget {
  final String personName;
  final double netBalance;
  final List<dynamic> transactions; // لیستی هەموو وەسڵەکانی ئەم کەسە

  const PersonAccountScreen({
    super.key,
    required this.personName,
    required this.netBalance,
    required this.transactions,
  });

  // دیالۆگی دەستکاریکردنی وەسڵ
  Future<void> _showEditTransactionDialog(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    final currentAmount = (data['amount'] ?? 0).toDouble().toString();
    final currentNote = data['note'] ?? '';

    final amountController = TextEditingController(text: currentAmount);
    final noteController = TextEditingController(text: currentNote);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('دەستکاریکردنی وەسڵ', textAlign: TextAlign.right),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'بڕی قەرز',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'تکایە بڕی قەرز بنووسە';
                    if (double.tryParse(value) == null)
                      return 'تکایە ژمارەی دروست بنووسە';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteController,
                  textAlign: TextAlign.right,
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
                  final newAmount = double.parse(amountController.text.trim());
                  final newNote = noteController.text.trim();

                  await FirebaseFirestore.instance
                      .collection('debts')
                      .doc(doc.id)
                      .update({'amount': newAmount, 'note': newNote});

                  if (context.mounted) {
                    Navigator.pop(context); // داخستنی دیالۆگەکە
                    Navigator.pop(
                      context,
                    ); // گەڕانەوە بۆ پەڕەی پێشوو بۆ تازەبوونەوەی داتاکان
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
        );
      },
    );
  }

  // دیالۆگی دڵنیابوونەوە لە سڕینەوە
  Future<void> _showDeleteDialog(BuildContext context, String docId) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'سڕینەوەی وەسڵ',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'ئایا دڵنیایت لە سڕینەوەی ئەم وەسڵە؟\nئەم کارە پاشگەزبوونەوەی تێدا نییە.',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('نەخێر', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('debts')
                    .doc(docId)
                    .delete();
                if (context.mounted) {
                  Navigator.pop(context); // داخستنی دیالۆگەکە
                  Navigator.pop(context); // گەڕانەوە بۆ پەڕەی پێشوو
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwedToMe = netBalance >= 0;
    final displayBalance = netBalance.abs();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'کەشف حسابی: $personName',
            textDirection: TextDirection.rtl,
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            // کارتی پوختەی حسابی کەسەکە
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'کۆی گشتی حساب تا ئەم ساتە',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '\$${displayBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isOwedToMe ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        isOwedToMe
                            ? 'ئەم کەسە قەرزارە'
                            : 'تۆ قەرزاری ئەم کەسەیت',
                        style: TextStyle(
                          fontSize: 16,
                          color: isOwedToMe ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'وردەکاری مامەڵەکان (وەسڵەکان)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // لیستی وەسڵەکانی ئەم کەسە
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final doc = transactions[index] as QueryDocumentSnapshot;
                  final data = doc.data() as Map<String, dynamic>;
                  final amount = (data['amount'] ?? 0).toDouble();
                  final isTransactionOwedToMe = data['isOwedToMe'] ?? true;
                  final note = data['note'] ?? 'بێ تێبینی';

                  final timestamp = data['date'] as Timestamp?;
                  final dateStr = timestamp != null
                      ? timestamp.toDate().toString().split(' ')[0]
                      : 'بێ بەروار';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isTransactionOwedToMe
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        child: Icon(
                          isTransactionOwedToMe
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: isTransactionOwedToMe
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      title: Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text('$dateStr\nتێبینی: $note'),
                      isThreeLine: true,
                      // لێرەدا کۆدەکە گۆڕدراوە بۆ ئەوەی دوگمەی دەستکاری و سڕینەوەی هەبێت
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Color(0xFF4A90E2),
                            ),
                            onPressed: () {
                              _showEditTransactionDialog(context, doc);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              _showDeleteDialog(context, doc.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
