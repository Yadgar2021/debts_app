import 'package:debts_app/widgets/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/debt_type_toggle.dart';
import '../widgets/custom_text_field.dart';

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
  String _selectedCurrency = 'USD';

  // لیستی ناوەکان بۆ ئۆتۆکۆمپلێت
  List<String> _existingNames = [];

  @override
  void initState() {
    super.initState();
    _fetchExistingNames(); // هێنانەوەی ناوەکان لەکاتی کردنەوەی پەڕەکە

    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['name'] ?? '';
      _amountController.text = (widget.existingData!['amount'] ?? 0).toString();
      _noteController.text = widget.existingData!['note'] ?? '';
      _isOwedToMe = widget.existingData!['isOwedToMe'] ?? true;
      _selectedCurrency = widget.existingData!['currency'] ?? 'USD';
      if (widget.existingData!['date'] != null) {
        _selectedDate = (widget.existingData!['date'] as Timestamp).toDate();
      }
    }
  }

  Future<void> _fetchExistingNames() async {
    try {
      // تەنها ناوەکان لە لیستی حسابە دروستکراوەکان (customers) دەهێنێت
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .get();
      final Set<String> names = {};
      for (var doc in snapshot.docs) {
        final name = (doc.data()['name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          names.add(name);
        }
      }
      if (mounted) {
        setState(() {
          _existingNames = names.toList();
        });
      }
    } catch (e) {
      debugPrint('هەڵە لە هێنانەوەی ناوەکان: $e');
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
          // لێرەدا کێشەکەی پێشووم چارەسەر کرد کە کۆدەکەی دەوەستاند
          'name': _nameController.text.trim(),
          'amount': double.parse(_amountController.text.trim()),
          'currency': _selectedCurrency,
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          isEditing ? 'دەستکاریکردنی قەرز' : 'قەرزێکی نوێ',
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DebtTypeToggle(
                      isOwedToMe: _isOwedToMe,
                      onChanged: (value) => setState(() => _isOwedToMe = value),
                    ),
                    const SizedBox(height: 24),

                    // خانەی ناوەکە بە شێوازی گەڕان و هەڵبژاردن
                    Autocomplete<String>(
                      initialValue: TextEditingValue(
                        text: _nameController.text,
                      ),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        // ئەگەر خانەکە بەتاڵ بوو، هەموو ناوەکان نیشان بدە
                        if (textEditingValue.text.isEmpty) {
                          return _existingNames;
                        }
                        // ئەگەر دەستی بە نووسین کرد، ناوەکان فلتەر بکە
                        return _existingNames.where((String option) {
                          return option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          );
                        });
                      },
                      onSelected: (String selection) {
                        _nameController.text = selection;
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            // بەستنەوەی نووسینەکە بە کۆنتڕۆڵەرە سەرەکییەکەوە
                            textEditingController.addListener(() {
                              _nameController.text = textEditingController.text;
                            });

                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'ناوی کەسەکە',
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Color(0xFF4A90E2),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'تکایە ناوێک بنووسە یان هەڵبژێرە';
                                }
                                if (!_existingNames.contains(value)) {
                                  return 'ئەم کەسە حسابی نییە، سەرەتا حسابی بۆ بکەوە';
                                }
                                return null;
                              },
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(15),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                maxWidth: 300,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(
                                    index,
                                  );
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _amountController,
                      labelText: 'بڕی پارە',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
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

                    CustomTextField(
                      controller: _noteController,
                      labelText: 'تێبینی (ئارەزوومەندانە)',
                      prefixIcon: Icons.note,
                      maxLines: 3,
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
        ),
      ),
    );
  }
}
