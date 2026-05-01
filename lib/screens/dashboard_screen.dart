import 'package:debts_app/screens/add_account_screen.dart';
import 'package:debts_app/screens/customers_screen.dart';
import 'package:debts_app/widgets/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_debt_screen.dart';
import '../widgets/summary_card.dart';
import 'person_account_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  late Stream<QuerySnapshot> _debtsStream;

  // گۆڕاوە نوێیەکان بۆ فلتەر و ڕیزبەندی
  String _filterType = 'all'; // all, owedToMe, iOwe
  bool _sortDescending =
      true; // true: زۆرترین بۆ کەمترین, false: کەمترین بۆ زۆرترین

  @override
  void initState() {
    super.initState();
    _debtsStream = FirebaseFirestore.instance
        .collection('debts')
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // مێنیوی دوگمەی زیادکردن
  void _showAddBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl, // بۆ ڕاستکردنەوەی ئاراستەی کوردی
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF4A90E2),
                      child: Icon(Icons.person_add, color: Colors.white),
                    ),
                    title: const Text(
                      'کردنەوەی حسابی نوێ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text(
                      'بۆ زیادکردنی کەسێکی نوێ بە ناو و ژمارە مۆبایل',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAccountScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(indent: 70, endIndent: 20),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.post_add, color: Colors.white),
                    ),
                    title: const Text(
                      'زیادکردنی قەرز',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text('بۆ تۆمارکردنی وەسڵ یان قەرزێکی نوێ'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddDebtScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'قەرزەکانم',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.people_alt,
                color: Color.fromARGB(255, 18, 2, 134),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomersScreen(),
                  ),
                );
              },
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _debtsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SelectableText(
                      'هەڵە هەیە: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDebts = snapshot.data?.docs ?? [];
              double totalOwedToMe = 0;
              double totalIOwe = 0;

              Map<String, Map<String, dynamic>> groupedPersons = {};

              for (var doc in allDebts) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] ?? 0).toDouble();
                final isOwedToMe = data['isOwedToMe'] ?? true;
                final rawName = (data['name'] ?? 'بێناو').toString().trim();
                final nameKey = rawName.toLowerCase();
                final phone = data['phone'] ?? 'مۆبایل نەنووسراوە';

                if (!groupedPersons.containsKey(nameKey)) {
                  groupedPersons[nameKey] = {
                    'displayName': rawName,
                    'phone': phone,
                    'netBalance': 0.0,
                    'transactions': [],
                  };
                } else if (phone != 'مۆبایل نەنووسراوە' &&
                    groupedPersons[nameKey]!['phone'] == 'مۆبایل نەنووسراوە') {
                  groupedPersons[nameKey]!['phone'] = phone;
                }

                if (isOwedToMe) {
                  groupedPersons[nameKey]!['netBalance'] += amount;
                } else {
                  groupedPersons[nameKey]!['netBalance'] -= amount;
                }

                groupedPersons[nameKey]!['transactions'].add(doc);
              }

              final List<Map<String, dynamic>> activePersons = [];

              for (var person in groupedPersons.values) {
                final balance = person['netBalance'] as double;
                if (balance.abs() > 0.001) {
                  activePersons.add(person);
                  if (balance > 0) {
                    totalOwedToMe += balance;
                  } else {
                    totalIOwe += balance.abs();
                  }
                }
              }

              // ==========================================
              // دۆزینەوەی ژمارەی حسابەکان بۆ فلتەرەکان
              // ==========================================
              final int allCount = activePersons.length;
              final int owedToMeCount = activePersons
                  .where((p) => (p['netBalance'] as double) > 0)
                  .length;
              final int iOweCount = activePersons
                  .where((p) => (p['netBalance'] as double) < 0)
                  .length;

              // 1. فلتەرکردن بەپێی گەڕان و جۆری قەرز بۆ لیستی پیشاندراو
              var filteredPersons = activePersons.where((person) {
                // فلتەری ناو
                final name = person['displayName'].toString().toLowerCase();
                final matchesSearch = name.contains(searchQuery.toLowerCase());
                if (!matchesSearch) return false;

                // فلتەری جۆری قەرز
                final balance = person['netBalance'] as double;
                if (_filterType == 'owedToMe' && balance <= 0) return false;
                if (_filterType == 'iOwe' && balance >= 0) return false;

                return true;
              }).toList();

              // 2. ڕیزبەندکردن (Sorting)
              filteredPersons.sort((a, b) {
                final balanceA = (a['netBalance'] as double).abs();
                final balanceB = (b['netBalance'] as double).abs();

                if (_sortDescending) {
                  return balanceB.compareTo(balanceA); // زۆرترین بۆ کەمترین
                } else {
                  return balanceA.compareTo(balanceB); // کەمترین بۆ زۆرترین
                }
              });

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SummaryCard(
                      totalOwedToMe: totalOwedToMe,
                      totalIOwe: totalIOwe,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'گەڕان بۆ ناو...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // بەشی فلتەر و ڕیزبەندی لەگەڵ ژمارەی وەسڵەکان
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // دوگمەی ڕیزبەندی
                          InkWell(
                            onTap: () {
                              setState(() {
                                _sortDescending = !_sortDescending;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _sortDescending
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    size: 18,
                                    color: const Color(0xFF4A90E2),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _sortDescending ? 'زۆرترین' : 'کەمترین',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4A90E2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // فلتەرەکان بە ژمارەوە
                          ChoiceChip(
                            label: Text('هەمووی ($allCount)'),
                            selected: _filterType == 'all',
                            onSelected: (selected) {
                              if (selected) setState(() => _filterType = 'all');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('قەرزیان لایە ($owedToMeCount)'),
                            selectedColor: Colors.green.shade100,
                            selected: _filterType == 'owedToMe',
                            onSelected: (selected) {
                              if (selected)
                                setState(() => _filterType = 'owedToMe');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('قەرزیان لامە ($iOweCount)'),
                            selectedColor: Colors.red.shade100,
                            selected: _filterType == 'iOwe',
                            onSelected: (selected) {
                              if (selected)
                                setState(() => _filterType = 'iOwe');
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),
                    const Text(
                      'لیستی قەرزەکان',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredPersons.isEmpty
                          ? const Center(
                              child: Text(
                                'هیچ قەرزێکت نیە',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredPersons.length,
                              itemBuilder: (context, index) {
                                final person = filteredPersons[index];
                                final balance = person['netBalance'] as double;
                                final transactionCount =
                                    (person['transactions'] as List).length;
                                final isOwedToMe = balance >= 0;
                                final displayBalance = balance.abs();

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PersonAccountScreen(
                                                personName:
                                                    person['displayName'],
                                                personPhone: person['phone'],
                                                netBalance: balance,
                                                transactions:
                                                    person['transactions'],
                                              ),
                                        ),
                                      );
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: isOwedToMe
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      child: Icon(
                                        Icons.person,
                                        color: isOwedToMe
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    title: Text(
                                      person['displayName'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '$transactionCount مامەڵە کراوە',
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${displayBalance.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isOwedToMe
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        Text(
                                          isOwedToMe ? 'قەرزارە' : 'قەرزاریت',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isOwedToMe
                                                ? Colors.green
                                                : Colors.red,
                                          ),
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
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddBottomSheet(context),
            backgroundColor: const Color(0xFF4A90E2),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
