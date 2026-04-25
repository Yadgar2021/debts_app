import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/debt_type_toggle.dart'; // ئەمەمان زیاد کردووە

class AddDebtScreen extends StatefulWidget {
  final String? debtId;
  final Map<String, dynamic>? existingData;

  const AddDebtScreen({super.key, this.debtId, this.existingData});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isOwedToMe = true;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['name'] ?? '';
      _amountController.text = (widget.existingData!['amount'] ?? 0).toString();
      _noteController.text = widget.existingData!['note'] ?? '';
      _isOwedToMe = widget.existingData!['isOwedToMe'] ?? true;
      if (widget.existingData!['date'] != null) {
        _selectedDate = (widget.existingData!['date'] as Timestamp).toDate();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveDebt() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final debtData = {
          'name': _nameController.text.trim(),
          'amount': double.parse(_amountController.text.trim()),
          'isOwedToMe': _isOwedToMe,
          'date': Timestamp.fromDate(_selectedDate),
          'note': _noteController.text.trim(),
        };

        if (widget.debtId == null) {
          debtData['createdAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('debts').add(debtData);
        } else {
          await FirebaseFirestore.instance
              .collection('debts')
              .doc(widget.debtId)
              .update(debtData);
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('کێشەیەک ڕوویدا: $e')));
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.debtId != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'دەستکاریکردنی قەرز' : 'قەرزێکی نوێ',
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // بەکارهێنانی فایلە نوێیەکە لێرەدا
                DebtTypeToggle(
                  isOwedToMe: _isOwedToMe,
                  onChanged: (value) {
                    setState(() {
                      _isOwedToMe = value;
                    });
                  },
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'ناوی کەسەکە',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'تکایە ناو بنووسە' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'بڕی پارە',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'تکایە بڕی پارە بنووسە' : null,
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'بەروار',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'تێبینی (ئارەزوومەندانە)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _saveDebt,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF4A90E2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing
                              ? 'هەڵگرتنی گۆڕانکارییەکان'
                              : 'زیادکردنی قەرز',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
