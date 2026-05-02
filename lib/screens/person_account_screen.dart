import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dialog.dart'; // دڵنیابە لەم پاتە
import '../widgets/gradient_background.dart'; // دڵنیابە لەم پاتە

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
  String _filterType = 'all';

  // گۆڕاو بۆ کۆنترۆڵکردنی دۆخی کارتەکە (گەورە یان بچووک)
  bool _isCardExpanded = true;

  // گۆڕاوە لۆکاڵییەکان بۆ هێشتنەوەی پەڕەکە بێ ئەوەی بگەڕێتەوە داشبۆرد
  late List<dynamic> _localTransactions;
  late double _localNetBalance;

  // کۆنتڕۆڵەری سکرۆڵ بۆ زانینی کاتی چوونە خوارەوە
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    currentPhone = widget.personPhone;

    // خستنە ناوەوەی داتاکان بۆ گۆڕاوە لۆکاڵییەکان
    _localTransactions = List.from(widget.transactions);
    _localNetBalance = widget.netBalance;

    _checkAndFetchPhone();

    // گوێگرتن لە سکرۆڵەکە بۆ بچووککردنەوە و گەورەکردنی کارتەکە
    _scrollController.addListener(() {
      if (_scrollController.offset > 30 && _isCardExpanded) {
        setState(() {
          _isCardExpanded = false;
        });
      } else if (_scrollController.offset < 10 && !_isCardExpanded) {
        setState(() {
          _isCardExpanded = true;
        });
      }
    });
  }

  // پاککردنەوەی میمۆری لە کاتی چوونە دەرەوە لە پەڕەکە
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            if (mounted) setState(() => currentPhone = fetchedPhone);
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

    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('نەتوانرا پەیوەندی بکرێت، مۆڵەت دراوە بە ئاپەکە؟'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هەڵەیەک ڕوویدا لە کاتی پەیوەندیکردندا'),
          ),
        );
      }
    }
  }

  // فەنکشنی هێنانەوەی قەرزەکان دوای زیادکردن یان دەستکاریکردن
  Future<void> _refreshTransactions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('debts')
          .where('name', isEqualTo: widget.personName)
          .get();

      double newBalance = 0;
      List<dynamic> nonArchivedTransactions = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // ئەگەر ئەرشیف کرابوو با نەیگەرێنێتەوە
        final isArchived = data['isArchived'] ?? false;
        if (isArchived) continue;

        nonArchivedTransactions.add(doc);
        final amount = (data['amount'] ?? 0).toDouble();
        final isOwedToMe = data['isOwedToMe'] ?? true;

        if (isOwedToMe) {
          newBalance += amount;
        } else {
          newBalance -= amount;
        }
      }

      if (mounted) {
        setState(() {
          _localTransactions = nonArchivedTransactions;
          _localNetBalance = newBalance;
        });
      }
    } catch (e) {
      debugPrint('هەڵە لە هێنانەوەی داتاکان: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwedToMe = _localNetBalance >= 0;
    final displayBalance = _localNetBalance.abs();

    List<dynamic> sortedDocs = List.from(_localTransactions);
    sortedDocs.sort((a, b) {
      final tA = (a as QueryDocumentSnapshot).data() as Map<String, dynamic>;
      final tB = (b as QueryDocumentSnapshot).data() as Map<String, dynamic>;
      final dateA = tA['date'] as Timestamp?;
      final dateB = tB['date'] as Timestamp?;
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    Set<String> zeroPointDocIds = {};
    double runningBalance = 0.0;

    for (int i = sortedDocs.length - 1; i >= 0; i--) {
      final doc = sortedDocs[i] as QueryDocumentSnapshot;
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] ?? 0).toDouble();
      final isTransactionOwedToMe = data['isOwedToMe'] ?? true;

      if (isTransactionOwedToMe) {
        runningBalance += amount;
      } else {
        runningBalance -= amount;
      }

      if (runningBalance.abs() < 0.001) {
        zeroPointDocIds.add(doc.id);
      }
    }

    final int allCount = sortedDocs.length;
    final int givenCount = sortedDocs.where((doc) {
      final data =
          (doc as QueryDocumentSnapshot).data() as Map<String, dynamic>;
      return data['isOwedToMe'] ?? true;
    }).length;

    final int takenCount = sortedDocs.where((doc) {
      final data =
          (doc as QueryDocumentSnapshot).data() as Map<String, dynamic>;
      return !(data['isOwedToMe'] ?? true);
    }).length;

    List<dynamic> displayDocs = sortedDocs.where((doc) {
      final data =
          (doc as QueryDocumentSnapshot).data() as Map<String, dynamic>;
      final isTransactionOwedToMe = data['isOwedToMe'] ?? true;

      if (_filterType == 'given') return isTransactionOwedToMe;
      if (_filterType == 'taken') return !isTransactionOwedToMe;
      return true;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'کەشف حسابی: ${widget.personName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              AccountSummaryCard(
                displayBalance: displayBalance,
                isOwedToMe: isOwedToMe,
                currentPhone: currentPhone,
                isExpanded: _isCardExpanded,
                onToggle: () {
                  setState(() {
                    _isCardExpanded = !_isCardExpanded;
                  });
                },
                onGivePressed: () async {
                  await PersonAccountDialogs.showAddTransactionDialog(
                    context,
                    widget.personName,
                    true,
                  );
                  await _refreshTransactions();
                },
                onTakePressed: () async {
                  await PersonAccountDialogs.showAddTransactionDialog(
                    context,
                    widget.personName,
                    false,
                  );
                  await _refreshTransactions();
                },
                onArchivePressed: () async {
                  await PersonAccountDialogs.showArchiveDialog(
                    context,
                    _localTransactions,
                  );
                  await _refreshTransactions();
                },
                onCallPressed: () => _makePhoneCall(context, currentPhone),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'وردەکاری مامەڵەکان (وەسڵەکان)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('هەمووی ($allCount)'),
                      selected: _filterType == 'all',
                      onSelected: (selected) {
                        if (selected) setState(() => _filterType = 'all');
                      },
                      selectedColor: Colors.teal.shade100,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('پێدانی قەرز ($givenCount)'),
                      selected: _filterType == 'given',
                      onSelected: (selected) {
                        if (selected) setState(() => _filterType = 'given');
                      },
                      selectedColor: Colors.red.shade100,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('وەرگرتنی قەرز ($takenCount)'),
                      selected: _filterType == 'taken',
                      onSelected: (selected) {
                        if (selected) setState(() => _filterType = 'taken');
                      },
                      selectedColor: Colors.green.shade100,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: displayDocs.isEmpty
                    ? const Center(
                        child: Text(
                          'هیچ وەسڵێک نییە بۆ ئەم جۆرە',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.all(16),
                        itemCount: displayDocs.length,
                        itemBuilder: (context, index) {
                          final doc =
                              displayDocs[index] as QueryDocumentSnapshot;
                          final bool broughtToZero = zeroPointDocIds.contains(
                            doc.id,
                          );

                          return Column(
                            children: [
                              if (broughtToZero)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(
                                          color: Colors.teal,
                                          thickness: 1.5,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.teal,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Text(
                                          'لەم کاتەدا حساب سفر بووەتەوە',
                                          style: TextStyle(
                                            color: Colors
                                                .teal, // ڕەنگەکەیم ڕێکخستەوە بۆ زیاتر گونجان
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(
                                          color: Colors.teal,
                                          thickness: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              TransactionListItem(
                                doc: doc,
                                onEdit: () async {
                                  await PersonAccountDialogs.showEditTransactionDialog(
                                    context,
                                    doc,
                                  );
                                  await _refreshTransactions();
                                },
                                onDelete: () async {
                                  final bool? isDeleted =
                                      await PersonAccountDialogs.showDeleteDialog(
                                        context,
                                        doc.id,
                                      );

                                  if (isDeleted == true) {
                                    setState(() {
                                      _localTransactions.removeWhere(
                                        (t) =>
                                            (t as QueryDocumentSnapshot).id ==
                                            doc.id,
                                      );

                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final amount = (data['amount'] ?? 0)
                                          .toDouble();
                                      final isTransactionOwedToMe =
                                          data['isOwedToMe'] ?? true;

                                      if (isTransactionOwedToMe) {
                                        _localNetBalance -= amount;
                                      } else {
                                        _localNetBalance += amount;
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
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

// ==========================================
// کارتی سەرەوە (قەبارە بچووککراوە و گەورە)
// ==========================================
class AccountSummaryCard extends StatelessWidget {
  final double displayBalance;
  final bool isOwedToMe;
  final String currentPhone;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onGivePressed;
  final VoidCallback onTakePressed;
  final VoidCallback onCallPressed;
  final VoidCallback onArchivePressed;

  const AccountSummaryCard({
    super.key,
    required this.displayBalance,
    required this.isOwedToMe,
    required this.currentPhone,
    required this.isExpanded,
    required this.onToggle,
    required this.onGivePressed,
    required this.onTakePressed,
    required this.onCallPressed,
    required this.onArchivePressed,
  });

  @override
  Widget build(BuildContext context) {
    // دیمەنی پیشاندانی باڵانسەکە بۆ ئەوەی دووبارەی نەکەینەوە
    Widget balanceWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '\$${displayBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isOwedToMe ? Colors.green : Colors.red,
            ),
            textDirection: TextDirection.ltr,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            isOwedToMe ? 'ئەم کەسە قەرزارە' : 'تۆ قەرزاری ئەم کەسەیت',
            style: TextStyle(
              fontSize: 12,
              color: isOwedToMe ? Colors.green : Colors.red,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // بەشی سەرەوەی کارتەکە (تایتڵ و دوگمەی کردنەوە/داخستن)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'کۆی گشتی حساب تا ئەم ساتە',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    InkWell(
                      onTap: onToggle,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.teal.withOpacity(0.1),
                        ),
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.teal,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // باڵانس و دوگمەکان
                if (isExpanded)
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: onGivePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  ' پێدانی قەرز',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(flex: 4, child: balanceWidget),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: onTakePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'وەرگرتنەوە',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // لە کاتی داخستندا تەنها باڵانسەکە دەمێنێتەوە
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0.0),
                    child: balanceWidget,
                  ),

                // بەشەکانی تری کارتەکە کە تەنها لە کاتی کراوەییدا دەردەکەون
                if (isExpanded) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(
                          0xFF4A90E2,
                        ).withOpacity(0.1),
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(
                            Icons.phone,
                            color: Color(0xFF4A90E2),
                            size: 20,
                          ),
                          onPressed: onCallPressed,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'ژمارە مۆبایل',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          Text(
                            currentPhone.isNotEmpty
                                ? currentPhone
                                : 'مۆبایل نەنووسراوە',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onArchivePressed,
                      icon: const Icon(
                        Icons.archive,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'پاکتاوکردنی حساب',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// دیزاینی وەسڵەکان
// ==========================================
class TransactionListItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionListItem({
    super.key,
    required this.doc,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final amount = (data['amount'] ?? 0).toDouble();
    final isTransactionOwedToMe = data['isOwedToMe'] ?? true;
    final note = data['note'] ?? 'بێ تێبینی';

    final timestamp = data['date'] as Timestamp?;
    String dateStr = 'بێ بەروار';

    if (timestamp != null) {
      final dateTime = timestamp.toDate();
      final String period = dateTime.hour >= 12 ? 'PM' : 'AM';
      int hour = dateTime.hour % 12;
      if (hour == 0) hour = 12;

      final minuteStr = dateTime.minute.toString().padLeft(2, '0');
      final dateOnly =
          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

      dateStr = '$dateOnly   $hour:$minuteStr $period';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isTransactionOwedToMe
              ? Colors.green.shade50
              : Colors.red.shade50,
          child: Icon(
            isTransactionOwedToMe ? Icons.arrow_upward : Icons.arrow_downward,
            color: isTransactionOwedToMe ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textDirection: TextDirection.ltr,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 4),
              Text('تێبینی: $note'),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF4A90E2)),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
