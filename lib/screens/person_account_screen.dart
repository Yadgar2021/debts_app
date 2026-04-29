import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/gradient_background.dart';

class PersonAccountScreen extends StatefulWidget {
  final String personName;
  final String personPhone;
  final double netBalance;
  final List<dynamic> transactions;

  const PersonAccountScreen({
    super.key,
    required this.personName,
    required this.personPhone,
    required this.netBalance,
    required this.transactions,
  });

  @override
  State<PersonAccountScreen> createState() => _PersonAccountScreenState();
}

class _PersonAccountScreenState extends State<PersonAccountScreen> {
  late String currentPhone;

  @override
  void initState() {
    super.initState();
    currentPhone = widget.personPhone;
    _checkAndFetchPhone();
  }

  Future<void> _checkAndFetchPhone() async {
    if (currentPhone == 'مۆبایل نەنووسراوە' || currentPhone.isEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('customers')
            .where('name', isEqualTo: widget.personName)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final fetchedPhone = snapshot.docs.first.data()['phone']?.toString();
          if (fetchedPhone != null && fetchedPhone.isNotEmpty) {
            if (mounted) {
              setState(() {
                currentPhone = fetchedPhone;
              });
            }
          }
        }
      } catch (e) {
        debugPrint('هەڵە لە هێنانی مۆبایل: $e');
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == 'مۆبایل نەنووسراوە') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ژمارە مۆبایل بەردەست نییە')),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'کێشە لە پەیوەندیکردندا هەیە';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نەتوانرا پەیوەندی بکرێت')),
        );
      }
    }
  }

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
                    if (value == null || value.isEmpty) {
                      return 'تکایە بڕی قەرز بنووسە';
                    }
                    if (double.tryParse(value) == null) {
                      return 'تکایە ژمارەی دروست بنووسە';
                    }
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
                    Navigator.pop(context);
                    Navigator.pop(context);
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
    ).then((_) {
      amountController.dispose();
      noteController.dispose();
    });
  }

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
                  Navigator.pop(context);
                  Navigator.pop(context);
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

  // 👈 ئەمە فەنکشنە نوێیەکەیە بۆ پاکتاوکردن و ئەرشیفکردنی مامەڵەکان
  Future<void> _showArchiveDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'پاکتاوکردنی حساب',
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'ئایا دڵنیایت دەتەوێت حسابی ئەم کەسە پاکتاو بکەیت؟\nئەمە هەموو وەسڵەکانی پێشوو ئەرشیف دەکات، و حسابەکەی پاک دەبێتەوە.',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('نەخێر', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                // بەکارهێنانی Batch بۆ ئەوەی هەموو وەسڵەکان بە یەکجاری و خێرا ئەپدەیت بن
                final batch = FirebaseFirestore.instance.batch();
                for (var doc in widget.transactions) {
                  final docRef = FirebaseFirestore.instance
                      .collection('debts')
                      .doc(doc.id);
                  // فیلدی ئەرشیف دەکەین بە ڕاست
                  batch.update(docRef, {'isArchived': true});
                }

                await batch.commit();

                if (context.mounted) {
                  Navigator.pop(context); // داخستنی دیالۆگەکە
                  Navigator.pop(context); // گەڕانەوە بۆ پەڕەی سەرەکی
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('حسابی کەسەکە بە سەرکەوتوویی پاکتاو کرا'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text(
                'بەڵێ، پاکتاوی بکە',
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
    final isOwedToMe = widget.netBalance >= 0;
    final displayBalance = widget.netBalance.abs();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'کەشف حسابی: ${widget.personName}',
            textDirection: TextDirection.rtl,
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(
                              0xFF4A90E2,
                            ).withOpacity(0.1),
                            radius: 25,
                            child: IconButton(
                              icon: const Icon(
                                Icons.phone,
                                color: Color(0xFF4A90E2),
                              ),
                              onPressed: () =>
                                  _makePhoneCall(context, currentPhone),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'ژمارە مۆبایل',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                currentPhone.isNotEmpty
                                    ? currentPhone
                                    : 'مۆبایل نەنووسراوە',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          ),
                        ],
                      ),
                      // 👈 دوگمەی پاکتاوکردن لێرەدا زیاد کراوە
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Divider(),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showArchiveDialog(context),
                          icon: const Icon(Icons.archive, color: Colors.white),
                          label: const Text(
                            'پاکتاوکردنی حساب',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
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

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.transactions.length,
                itemBuilder: (context, index) {
                  final doc =
                      widget.transactions[index] as QueryDocumentSnapshot;
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
