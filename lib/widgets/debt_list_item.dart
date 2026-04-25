import 'package:debts_app/screens/add_debt_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebtListItem extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const DebtListItem({super.key, required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'بێناو';
    final amount = (data['amount'] ?? 0).toDouble();
    final isOwedToMe = data['isOwedToMe'] ?? true;

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) async {
        await FirebaseFirestore.instance
            .collection('debts')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('قەرزی "$name" سڕدرایەوە'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.white.withOpacity(0.8),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: isOwedToMe
                ? Colors.green.shade100
                : Colors.red.shade100,
            child: Icon(
              isOwedToMe ? Icons.arrow_upward : Icons.arrow_downward,
              color: isOwedToMe ? Colors.green : Colors.red,
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            isOwedToMe ? 'پێم داوە' : 'لێم وەرگرتووە',
            style: TextStyle(
              color: isOwedToMe ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
          trailing: Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          onTap: () => _showDebtDetails(context),
        ),
      ),
    );
  }

  void _showDebtDetails(BuildContext context) {
    final name = data['name'] ?? 'بێناو';
    final amount = (data['amount'] ?? 0).toDouble();
    final isOwedToMe = data['isOwedToMe'] ?? true;
    final timestamp = data['date'] as Timestamp?;
    final date = timestamp != null ? timestamp.toDate() : DateTime.now();
    final dateString =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final note = data['note'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_document,
                        color: Color(0xFF4A90E2),
                        size: 28,
                      ),
                      onPressed: () {
                        // داخستنی پەنجەرەی خوارەوە (BottomSheet)
                        Navigator.pop(context);
                        // چوون بۆ پەڕەی دەستکاریکردن و ناردنی زانیارییەکان
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddDebtScreen(
                              debtId: docId,
                              existingData: data,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'بڕی پارە:',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isOwedToMe ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'بەروار:',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      dateString,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                const Text(
                  'تێبینی:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  note.isEmpty ? 'هیچ تێبینییەک نەنووسراوە' : note,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
