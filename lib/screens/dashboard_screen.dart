import 'package:debts_app/screens/add_account_screen.dart';
import 'package:debts_app/screens/customers_screen.dart';
import 'package:debts_app/widgets/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_debt_screen.dart';
import '../widgets/summary_card.dart';
// تێبینی: دڵنیابە لەوەی ئەم فایلە نوێیەت دروستکردووە کە پێشتر باسمان کرد
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

  @override
  void initState() {
    super.initState();
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
              fontSize: 22,
              color: Colors.black87,
            ),
          ),

          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.people_alt,
                color: Color.fromARGB(255, 18, 2, 134),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomersScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
            //   Text("لیستی ناوەکان"),
            // const SizedBox(width: 8),
          ],
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

            // ١. لۆژیکی کۆکردنەوەی قەرزەکان بەپێی ناو (Grouping)
            Map<String, Map<String, dynamic>> groupedPersons = {};

            for (var doc in allDebts) {
              final data = doc.data() as Map<String, dynamic>;
              final amount = (data['amount'] ?? 0).toDouble();
              final isOwedToMe = data['isOwedToMe'] ?? true;

              final rawName = (data['name'] ?? 'بێناو').toString().trim();
              final nameKey = rawName.toLowerCase();

              if (isOwedToMe) {
                totalOwedToMe += amount;
              } else {
                totalIOwe += amount;
              }

              if (!groupedPersons.containsKey(nameKey)) {
                groupedPersons[nameKey] = {
                  'displayName': rawName,
                  'netBalance': 0.0,
                  'transactions': [],
                };
              }

              if (isOwedToMe) {
                groupedPersons[nameKey]!['netBalance'] += amount;
              } else {
                groupedPersons[nameKey]!['netBalance'] -= amount;
              }

              groupedPersons[nameKey]!['transactions'].add(doc);
            }

            // فلتەرکردنی ناوە گروپ کراوەکان بەپێی گەڕان
            final filteredPersons = groupedPersons.values.where((person) {
              final name = person['displayName'].toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

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
                    textAlign: TextAlign.end,
                    controller: _searchController,
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: '...گەڕان بۆ ناو',
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
                  const SizedBox(height: 10),

                  const Center(
                    child: Text(
                      'لیستی قەرزەکان',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: filteredPersons.isEmpty
                        ? const Center(
                            child: Text(
                              'هیچ قەرزێکت نیە ',
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
                                    // چوونە ناو پەڕەی کەشف حسابی کەسەکە
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PersonAccountScreen(
                                              personName: person['displayName'],
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // کردنەوەی پەنجەرەی هەڵبژاردنەکان (Bottom Sheet)
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              builder: (context) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // هەڵبژاردەی یەکەم: کردنەوەی حسابی نوێ
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
                            Navigator.pop(context); // داخستنی پەنجەرە بچووکەکە
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddAccountScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(indent: 70, endIndent: 20),

                        // هەڵبژاردەی دووەم: زیادکردنی قەرز
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
                          subtitle: const Text(
                            'بۆ تۆمارکردنی وەسڵ یان قەرزێکی نوێ',
                          ),
                          onTap: () {
                            Navigator.pop(context); // داخستنی پەنجەرە بچووکەکە
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
                );
              },
            );
          },
          backgroundColor: const Color(0xFF4A90E2),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
