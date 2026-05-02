import '../reminders_screen.dart';
import 'add_account_screen.dart';
import 'customers_screen.dart';
import '../widgets/gradient_background.dart';
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
  // ئیندێکسی پەڕە دیاریکراوەکە لە خوارەوە
  int _selectedIndex = 0;

  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  late Stream<QuerySnapshot> _debtsStream;

  String _filterType = 'all';
  bool _sortDescending = true;

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

  void _showAddBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
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

  // ==========================================
  // پەڕەی یەکەم (سەرەکی) کە وەسڵەکانی تێدایە
  // ==========================================
  Widget _buildHomeContent() {
    return Scaffold(
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
        // تێبینی: دوگمەکانی سەرەوەم لابرد چونکە هاتوونەتە خوارەوە
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _debtsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'هەڵە هەیە: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
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

          final int allCount = activePersons.length;
          final int owedToMeCount = activePersons
              .where((p) => (p['netBalance'] as double) > 0)
              .length;
          final int iOweCount = activePersons
              .where((p) => (p['netBalance'] as double) < 0)
              .length;

          var filteredPersons = activePersons.where((person) {
            final name = person['displayName'].toString().toLowerCase();
            final matchesSearch = name.contains(searchQuery.toLowerCase());
            if (!matchesSearch) return false;

            final balance = person['netBalance'] as double;
            if (_filterType == 'owedToMe' && balance <= 0) return false;
            if (_filterType == 'iOwe' && balance >= 0) return false;

            return true;
          }).toList();

          filteredPersons.sort((a, b) {
            final balanceA = (a['netBalance'] as double).abs();
            final balanceB = (b['netBalance'] as double).abs();

            if (_sortDescending) {
              return balanceB.compareTo(balanceA);
            } else {
              return balanceA.compareTo(balanceB);
            }
          });

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SummaryCard(totalOwedToMe: totalOwedToMe, totalIOwe: totalIOwe),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'گەڕان بۆ ناو...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
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
                          if (selected) setState(() => _filterType = 'iOwe');
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
                                      builder: (context) => PersonAccountScreen(
                                        personName: person['displayName'],
                                        personPhone: person['phone'],
                                        netBalance: balance,
                                        transactions: person['transactions'],
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
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
    );
  }

  // ==========================================
  // دیزاینی ئایکۆنەکانی بەشی خوارەوە
  // ==========================================
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      customBorder: const CircleBorder(), // بۆ ئەوەی ئیفێکتی کلیکەکە جوان بێت
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF4A90E2) : Colors.grey.shade400,
            size: isSelected ? 26 : 24, // قەبارەمان کەمێک گونجاند
          ),
          const SizedBox(
            height: 2,
          ), // بۆشاییمان کەم کردەوە بۆ ڕێگریکردن لە ئۆڤەرفلۆ
          Flexible(
            // یارمەتیدەرە بۆ ڕێگریکردن لە دەرچوونی تێکست
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF4A90E2)
                      : Colors.grey.shade400,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ڕیزبەندی پەڕەکان
    final List<Widget> pages = [
      _buildHomeContent(),
      const CustomersScreen(),
      const RemindersScreen(),
      const Center(child: Text('پەڕەی ڕێکخستنەکان (بەمزوانە)')),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // IndexedStack بۆ هێشتنەوەی پەڕەکان بێ ئەوەی ڕیفرێش ببنەوە کاتێک دەگۆڕدرێن
          body: IndexedStack(index: _selectedIndex, children: pages),
          // دوگمەی ناوەڕاست (+)
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddBottomSheet(context),
            backgroundColor: const Color(0xFF4A90E2),
            elevation: 4,
            shape: const CircleBorder(), // بۆ ئەوەی بە تەواوی بازنەیی بێت
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
          // جێگیرکردنی دوگمەکە لە ناوەڕاست
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,

          // دیزاینی بەشی خوارەوە
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            color: Colors.white,
            elevation: 20,
            height: 65, // <-- ئەمە ڕێگری دەکات لە کێشەی بڕانی خوارەوە
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildNavItem(Icons.home_rounded, 'سەرەکی', 0)),
                Expanded(
                  child: _buildNavItem(
                    Icons.people_alt_rounded,
                    'کڕیارەکان',
                    1,
                  ),
                ),
                const SizedBox(width: 48), // بۆشایی بۆ دوگمەی شینەکەی ناوەڕاست
                Expanded(
                  child: _buildNavItem(
                    Icons.notifications_active_rounded,
                    'ئاگاداری',
                    2,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(Icons.settings_rounded, 'ڕێکخستن', 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
