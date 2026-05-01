import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/gradient_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_search_bar.dart'; // 👈 لێرەدا فایلە نوێیەکەمان هێناوەتە ژوورەوە

// 👈 تێبینی: دڵنیابە لەوەی پاتی ئەم فایلە ڕاستە بۆ ئەوەی پەڕەی کەشف حساب بناسێتەوە
import 'person_account_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  // 👈 گۆڕاوێک بۆ هەڵگرتنی ئەو وشەیەی بۆی دەگەڕێین
  String searchQuery = '';

  // دیالۆگێک بۆ دەستکاریکردنی زانیارییەکان
  Future<void> _showEditDialog(
    BuildContext context,
    String docId,
    String currentName,
    String currentPhone,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('دەستکاریکردنی حساب', textAlign: TextAlign.right),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  labelText: 'ناوی سیانی',
                  prefixIcon: Icons.person,
                  validator: (value) =>
                      value!.trim().isEmpty ? 'تکایە ناو بنووسە' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: phoneController,
                  labelText: 'ژمارە مۆبایل',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
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
                  final newName = nameController.text.trim();
                  final newPhone = phoneController.text.trim();

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    if (newName != currentName) {
                      final checkSnapshot = await FirebaseFirestore.instance
                          .collection('customers')
                          .where('name', isEqualTo: newName)
                          .get();

                      bool isDuplicate = false;
                      for (var doc in checkSnapshot.docs) {
                        if (doc.id != docId) {
                          isDuplicate = true;
                          break;
                        }
                      }

                      if (isDuplicate) {
                        if (mounted) Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'ئەم ناوە پێشتر بۆ کەسێکی تر تۆمار کراوە، تکایە ناوێکی تر بنووسە.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                    }

                    await FirebaseFirestore.instance
                        .collection('customers')
                        .doc(docId)
                        .update({'name': newName, 'phone': newPhone});

                    if (newName != currentName) {
                      final debtsSnapshot = await FirebaseFirestore.instance
                          .collection('debts')
                          .where('name', isEqualTo: currentName)
                          .get();

                      final batch = FirebaseFirestore.instance.batch();
                      for (var doc in debtsSnapshot.docs) {
                        batch.update(doc.reference, {'name': newName});
                      }
                      await batch.commit();
                    }

                    if (mounted) Navigator.pop(context);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) Navigator.pop(context);
                    debugPrint('هەڵە لە ئەپدەیتکردن: $e');
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
      nameController.dispose();
      phoneController.dispose();
    });
  }

  // دیالۆگێک بۆ دڵنیابوونەوە لە سڕینەوەی حساب
  Future<void> _showDeleteDialog(
    BuildContext context,
    String docId,
    String name,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'سڕینەوەی حساب',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            textDirection: TextDirection.rtl,
            'ئایا دڵنیایت لە سڕینەوەی حسابی "$name"؟\n\nتێبینی: ئەگەر ئەم کەسە قەرزی لایە، قەرزەکانی ناسڕێنەوە و تەنها ناوەکەی دەسڕێتەوە.',
            textAlign: TextAlign.right,
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
                await FirebaseFirestore.instance
                    .collection('customers')
                    .doc(docId)
                    .delete();
                if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'لیستی کڕیارەکان',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 👈 بەکارهێنانی ویدجێتی گەڕانە نوێیەکەمان
              CustomSearchBar(
                hintText: 'گەڕان بۆ ناو...',
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),

              // بەشی پیشاندانی لیستەکە
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('customers')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'هیچ حسابێک بوونی نییە',
                          style: TextStyle(color: Colors.black54, fontSize: 18),
                        ),
                      );
                    }

                    // 👈 فلتەرکردنی ناوەکان بەپێی گەڕانەکە
                    final allCustomers = snapshot.data!.docs;
                    final filteredCustomers = allCustomers.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '')
                          .toString()
                          .toLowerCase();
                      return name.contains(searchQuery);
                    }).toList();

                    if (filteredCustomers.isEmpty) {
                      return const Center(
                        child: Text(
                          'ئەو ناوە نەدۆزرایەوە',
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final doc = filteredCustomers[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'بێناو';
                        final rawPhone = data['phone']?.toString().trim() ?? '';
                        final phone = rawPhone.isEmpty
                            ? 'مۆبایل نەنووسراوە'
                            : rawPhone;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            // 👈 کاتێک کلیک لە ناوێک دەکەیت دەتباتە پەڕەی کەشف حساب
                            onTap: () async {
                              // ١. نیشاندانی ئایکۆنی لۆدینگ بۆ چرکەیەک تا داتاکان دەهێنێت
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                // ٢. هێنانەوەی هەموو وەسڵە ئەرشیف نەکراوەکانی ئەم کەسە
                                final debtsSnapshot = await FirebaseFirestore
                                    .instance
                                    .collection('debts')
                                    .where('name', isEqualTo: name)
                                    .where('isArchived', isEqualTo: false)
                                    .get();

                                double totalBalance = 0;
                                final transactions = debtsSnapshot.docs;

                                // ٣. کۆکردنەوەی بڕی قەرزەکان (باڵانس)
                                for (var doc in transactions) {
                                  final debtData =
                                      doc.data() as Map<String, dynamic>;
                                  final amount = (debtData['amount'] ?? 0)
                                      .toDouble();
                                  final isOwedToMe =
                                      debtData['isOwedToMe'] ?? true;

                                  if (isOwedToMe) {
                                    totalBalance += amount;
                                  } else {
                                    totalBalance -= amount;
                                  }
                                }

                                // ٤. لابردنی ئایکۆنی لۆدینگەکە
                                if (context.mounted) Navigator.pop(context);

                                // ٥. چوونە ناو پەڕەی کەشف حساب بە داتا ڕاستەقینەکانەوە
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PersonAccountScreen(
                                        personName: name,
                                        personPhone: phone,
                                        netBalance: totalBalance,
                                        transactions: transactions,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) Navigator.pop(context);
                                debugPrint('هەڵە لە هێنانی داتای قەرزەکان: $e');
                              }
                            },
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF4A90E2),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(phone),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF4A90E2),
                                    ),
                                    onPressed: () {
                                      _showEditDialog(
                                        context,
                                        doc.id,
                                        name,
                                        rawPhone,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      _showDeleteDialog(context, doc.id, name);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
