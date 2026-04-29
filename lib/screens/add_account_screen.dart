import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/gradient_background.dart';
import '../widgets/custom_text_field.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final newName = _nameController.text.trim();

        // هەنگاوی یەکەم: پشکنین دەکەین بزانین ئەم ناوە لە لیستی 'customers' دا هەیە یان نا
        final checkSnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .where('name', isEqualTo: newName) // گەڕان بەدوای هەمان ناو
            .get();

        // ئەگەر لیستەکە بەتاڵ نەبوو، واتە ناوەکە پێشتر هەیە
        if (checkSnapshot.docs.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'ئەم ناوە پێشتر تۆمار کراوە، تکایە ناوێکی تر بنووسە.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
          }
          return; // کۆدەکە لێرەدا دەوەستێت و ناچێتە خوارەوە بۆ خەزنکردن
        }

        // هەنگاوی دووەم: ئەگەر ناوەکە پێشتر نەبوو، ئەوا بە ئاسایی خەزنی دەکەین
        final customerData = {
          'name': newName,
          // هەر زانیارییەکی تری کڕیار کە هەتە لێرە دایبنێ...
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('customers')
            .add(customerData);

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('کێشەیەک ڕوویدا: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'کردنەوەی حسابی نوێ',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'ناوی سیانی',
                    prefixIcon: Icons.person,
                    validator: (value) =>
                        value!.isEmpty ? 'تکایە ناو بنووسە' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'ژمارە مۆبایل',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveCustomer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF4A90E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'تۆمارکردنی حساب',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
