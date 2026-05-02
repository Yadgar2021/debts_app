import '../widgets/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/debt_type_toggle.dart';
import '../widgets/custom_text_field.dart';
import '../notification_service.dart'; // 👈 ئەمەمان زیادکرد بۆ نۆتیفیکەیشنەکە

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
  DateTime? _selectedDueDate; // 👈 ئەمە بۆ کاتی گەڕاندنەوەی قەرزەکەیە
  bool _isLoading = false;
  String _selectedCurrency = 'USD';

  List<String> _existingNames = [];

  @override
  void initState() {
    super.initState();
    _fetchExistingNames();

    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['name'] ?? '';
      _amountController.text = (widget.existingData!['amount'] ?? 0).toString();
      _noteController.text = widget.existingData!['note'] ?? '';
      _isOwedToMe = widget.existingData!['isOwedToMe'] ?? true;
      _selectedCurrency = widget.existingData!['currency'] ?? 'USD';

      if (widget.existingData!['date'] != null) {
        _selectedDate = (widget.existingData!['date'] as Timestamp).toDate();
      }
      // 👈 هێنانەوەی کاتی گەڕاندنەوە ئەگەر پێشتر دانرابێت
      if (widget.existingData!['dueDate'] != null) {
        _selectedDueDate = (widget.existingData!['dueDate'] as Timestamp)
            .toDate();
      }
    }
  }

  Future<void> _fetchExistingNames() async {
    try {
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
      final amountValue = double.tryParse(_amountController.text.trim());
      if (amountValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تکایە بڕی پارەکە بە دروستی بنووسە')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final Map<String, dynamic> debtData = {
          'name': _nameController.text.trim(),
          'amount': amountValue,
          'currency': _selectedCurrency,
          'isOwedToMe': _isOwedToMe,
          'date': Timestamp.fromDate(_selectedDate),
          'note': _noteController.text.trim(),
          'isArchived': false,
        };

        // 👈 مامەڵەکردن لەگەڵ کاتی گەڕاندنەوە
        if (_selectedDueDate != null) {
          debtData['dueDate'] = Timestamp.fromDate(_selectedDueDate!);
        } else if (widget.debtId != null) {
          // ئەگەر کاتی گەڕاندنەوەکەی سڕییەوە لە کاتی دەستکاریکردندا
          debtData['dueDate'] = FieldValue.delete();
        }

        String currentDocId = widget.debtId ?? '';

        if (widget.debtId == null) {
          debtData['createdAt'] = FieldValue.serverTimestamp();
          final docRef = await FirebaseFirestore.instance
              .collection('debts')
              .add(debtData);
          currentDocId = docRef.id;
        } else {
          await FirebaseFirestore.instance
              .collection('debts')
              .doc(widget.debtId)
              .update(debtData);
        }

        // 👈 دانانی نۆتیفیکەیشن بەپێی بەروارەکە
        if (_selectedDueDate != null) {
          final scheduleTime = DateTime(
            _selectedDueDate!.year,
            _selectedDueDate!.month,
            _selectedDueDate!.day,
            9,
            0, // کاتژمێر ٩ی بەیانی
          );

          if (scheduleTime.isAfter(DateTime.now())) {
            await NotificationService().scheduleNotification(
              id: currentDocId.hashCode,
              title: _isOwedToMe
                  ? 'کاتی وەرگرتنەوەی پارە'
                  : 'کاتی دانەوەی قەرز',
              body: _isOwedToMe
                  ? 'کاتی وەرگرتنەوەی قەرزەکەی ${_nameController.text.trim()} هاتووە بە بڕی $amountValue.'
                  : 'کاتی دانەوەی قەرزەکەی ${_nameController.text.trim()} هاتووە بە بڕی $amountValue.',
              scheduledDate: scheduleTime,
            );
          }
        }

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
    final isEditing = widget.debtId != null;

    return GradientBackground(
      child: Scaffold(
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
        body: SafeArea(
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

                    Autocomplete<String>(
                      initialValue: TextEditingValue(
                        text: _nameController.text,
                      ),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        _nameController.text = textEditingValue.text;
                        if (textEditingValue.text.isEmpty) {
                          return _existingNames;
                        }
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
                                if (value == null || value.trim().isEmpty) {
                                  return 'تکایە ناوێک بنووسە یان هەڵبژێرە';
                                }
                                if (!_existingNames.contains(value.trim())) {
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
                                    onTap: () => onSelected(option),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'تکایە بڕی پارە بنووسە';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'تکایە تەنها ژمارە بەکاربهێنە';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // بەرواری وەرگرتنی قەرزەکە
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'بەرواری وەرگرتن/پێدان',
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

                    // 👈 ئەمە زیادکرا بۆ دیاریکردنی کاتی گەڕاندنەوە (نۆتیفیکەیشن)
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _selectedDueDate ??
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          helpText: 'کاتی گەڕاندنەوە دیاری بکە',
                          cancelText: 'پاشگەزبوونەوە',
                          confirmText: 'هەڵبژاردن',
                        );
                        if (picked != null && picked != _selectedDueDate) {
                          setState(() {
                            _selectedDueDate = picked;
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
                          borderRadius: BorderRadius.circular(
                            15,
                          ), // وەک دیزاینی فۆڕمەکانی تر
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_available_rounded,
                              color: Color(0xFF4A90E2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDueDate == null
                                  ? 'کاتی گەڕاندنەوە (ئارەزوومەندانە)'
                                  : 'گەڕاندنەوە: ${_selectedDueDate!.year}/${_selectedDueDate!.month}/${_selectedDueDate!.day}',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDueDate == null
                                    ? Colors.grey.shade700
                                    : Colors.black87,
                                fontWeight: _selectedDueDate != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (_selectedDueDate != null)
                              InkWell(
                                onTap: () =>
                                    setState(() => _selectedDueDate = null),
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
