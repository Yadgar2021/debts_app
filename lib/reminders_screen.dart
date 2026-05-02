import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //automaticallyImplyLeading: false,
        title: const Text(
          'بیرخستنەوەکان',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          color: Colors.grey.shade50,
          child: StreamBuilder<QuerySnapshot>(
            // هێنانی هەموو ئەو قەرزانەی کە ئەرشیف نەکراون
            stream: FirebaseFirestore.instance
                .collection('debts')
                .where('isArchived', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              // پاڵاوتن (فلتەرکردن) بۆ تەنها ئەوانەی بەرواریان هەیە
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data.containsKey('dueDate') && data['dueDate'] != null;
              }).toList();

              // ڕیزکردنیان بەپێی بەروار (کۆنترین بۆ نوێترین)
              docs.sort((a, b) {
                final dateA =
                    (a.data() as Map<String, dynamic>)['dueDate'] as Timestamp;
                final dateB =
                    (b.data() as Map<String, dynamic>)['dueDate'] as Timestamp;
                return dateA.compareTo(dateB);
              });

              if (docs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final dueDate = (data['dueDate'] as Timestamp).toDate();
                  final name = data['name'] ?? 'نەناسراو';
                  final amount = data['amount'] ?? 0.0;
                  final isOwedToMe = data['isOwedToMe'] ?? true;

                  // ژماردنی ڕۆژە ماوەکان یان تێپەڕیوەکان
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final dueDay = DateTime(
                    dueDate.year,
                    dueDate.month,
                    dueDate.day,
                  );
                  final difference = dueDay.difference(today).inDays;

                  String statusText;
                  Color statusColor;

                  if (difference < 0) {
                    statusText = 'کاتی تێپەڕیوە بە ${difference.abs()} ڕۆژ';
                    statusColor = Colors.red;
                  } else if (difference == 0) {
                    statusText = 'ئەمڕۆ کاتیەتی';
                    statusColor = Colors.orange.shade700;
                  } else {
                    statusText = '$difference ڕۆژی ماوە';
                    statusColor = Colors.green.shade600;
                  }

                  return Card(
                    elevation: 2,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isOwedToMe
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isOwedToMe
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isOwedToMe
                                  ? Colors.redAccent
                                  : Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'بڕی پارە: \$${amount.toString()}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${dueDate.year}/${dueDate.month}/${dueDate.day}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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

  // دیزاینی ئەو کاتەی کە هیچ بیرخستنەوەیەک بوونی نییە
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'هیچ کاتێکی گەڕاندنەوەت نییە',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'کاتێک کاتی قەرز دیاری دەکەیت، لێرە دەردەکەون',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
