import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/gradient_background.dart';
import '../widgets/custom_text_field.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

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
                      value!.isEmpty ? 'تکایە ناو بنووسە' : null,
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

                  // نیشاندانی لۆدینگ (چاوەڕێکردن) بۆ ئەوەی بەکارهێنەر بزانێت کارێک دەکرێت
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    // پشکنین: ئایا ناوەکە گۆڕاوە و بووەتە ناوێک کە پێشتر هەیە؟
                    if (newName != currentName) {
                      final checkSnapshot = await FirebaseFirestore.instance
                          .collection('customers')
                          .where('name', isEqualTo: newName)
                          .get();

                      bool isDuplicate = false;
                      for (var doc in checkSnapshot.docs) {
                        // ئەگەر ناوەکە هەبوو وە ئایدییەکەی جیاواز بوو لەم کەسە، واتە هی کەسێکی ترە
                        if (doc.id != docId) {
                          isDuplicate = true;
                          break;
                        }
                      }

                      if (isDuplicate) {
                        // ١. لابردنی لۆدینگەکە
                        if (context.mounted) Navigator.pop(context);

                        // ٢. نیشاندانی ئاگادارکەرەوە
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'ئەم ناوە پێشتر بۆ کەسێکی تر تۆمار کراوە، تکایە ناوێکی تر بنووسە.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return; // وەستاندنی پرۆسەی خەزنکردن
                      }
                    }

                    // ئەگەر ناوەکە کێشەی نەبوو یان تەنها ژمارە مۆبایلەکەی گۆڕیبوو:
                    // ١. ئەپدەیتکردنی حسابەکە لە کۆلێکشنی customers
                    await FirebaseFirestore.instance
                        .collection('customers')
                        .doc(docId)
                        .update({'name': newName, 'phone': newPhone});

                    // ٢. ئەگەر ناوەکە گۆڕابوو، ئەوا لەناو قەرزەکانیش بیگۆڕە
                    if (newName != currentName) {
                      // هێنانەوەی هەموو ئەو قەرزانەی کە بە ناوە کۆنەکەوەن
                      final debtsSnapshot = await FirebaseFirestore.instance
                          .collection('debts')
                          .where('name', isEqualTo: currentName)
                          .get();

                      // بەکارهێنانی Batch بۆ ئەوەی هەموو قەرزەکان بەیەکەوە و بە خێرایی ئەپدەیت بکات
                      final batch = FirebaseFirestore.instance.batch();
                      for (var doc in debtsSnapshot.docs) {
                        batch.update(doc.reference, {'name': newName});
                      }
                      await batch.commit(); // جێبەجێکردنی هەموو گۆڕانکارییەکان
                    }

                    // لابردنی لۆدینگەکە
                    if (context.mounted) Navigator.pop(context);
                    // داخستنی دیالۆگی دەستکاریکردنەکە
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    // لابردنی لۆدینگەکە ئەگەر هەڵەیەک ڕوویدا
                    if (context.mounted) Navigator.pop(context);
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
    );
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
                // سڕینەوەی دۆکیومێنتەکە لە فایەربەیس
                await FirebaseFirestore.instance
                    .collection('customers')
                    .doc(docId)
                    .delete();
                if (context.mounted) {
                  Navigator.pop(context); // داخستنی دیالۆگەکە
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
          'لیستی ناوەکان',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: GradientBackground(
        child: SafeArea(
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

              final customers = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final doc = customers[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'بێناو';
                  final phone = data['phone'] ?? 'مۆبایل نەنووسراوە';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF4A90E2),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                              _showEditDialog(context, doc.id, name, phone);
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
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
