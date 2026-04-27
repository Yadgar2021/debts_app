import 'package:debts_app/widgets/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_debt_screen.dart';
import '../widgets/summary_card.dart';
import '../widgets/debt_list_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String searchQuery = "";

  // ١. ئامرازێکی مۆدێرن بۆ کۆنتڕۆڵکردنی خانەی نووسین بەبێ لەدەستدانی فۆکەس
  final TextEditingController _searchController = TextEditingController();

  // ٢. جیاکردنەوەی ستریمی داتابەیس بۆ ئەوەی لەگەڵ هەر پیتێکدا ڕیفڕێش نەبێتەوە
  late Stream<QuerySnapshot> _debtsStream;

  @override
  void initState() {
    super.initState();
    // ستریمەکە تەنها یەک جار لێرەدا ئامادە دەکرێت
    _debtsStream = FirebaseFirestore.instance
        .collection('debts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'قەرزەکانم',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _debtsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allDebts = snapshot.data?.docs ?? [];
            double totalOwedToMe = 0;
            double totalIOwe = 0;

            for (var doc in allDebts) {
              final data = doc.data() as Map<String, dynamic>;
              final amount = (data['amount'] ?? 0).toDouble();
              final isOwedToMe = data['isOwedToMe'] ?? true;

              if (isOwedToMe) {
                totalOwedToMe += amount;
              } else {
                totalIOwe += amount;
              }
            }

            final filteredDebts = allDebts.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              // لێرەدا Column بەکاردێنین بۆ ئەوەی بەشەکان جیا بکەینەوە
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ١. ئەم بەشەی سەرەوە هەمیشە جێگیر دەبێت
                  SummaryCard(
                    totalOwedToMe: totalOwedToMe,
                    totalIOwe: totalIOwe,
                  ),
                  const SizedBox(height: 12),

                  // بەشی گەڕانەکەش جێگیر دەبێت
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'لیستی قەرزەکان',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ٢. ئەم Expanded وادەکات تەنها ئەم بەشە جێگای بەتاڵ پڕبکاتەوە و سکڕۆڵ بێت
                  Expanded(
                    child: filteredDebts.isEmpty
                        ? const Center(
                            child: Text(
                              'هیچ قەرزێک نەدۆزرایەوە',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            // لێرەدا لەبری SliverList ئێستا ListView ئاسایی بەکاردێنین
                            itemCount: filteredDebts.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDebts[index];
                              return DebtListItem(
                                docId: doc.id,
                                data: doc.data() as Map<String, dynamic>,
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddDebtScreen()),
            );
          },
          backgroundColor: const Color(0xFF4A90E2),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
