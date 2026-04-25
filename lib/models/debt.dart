class Debt {
  final String id;
  final String name;
  final double amount;
  final bool
  isOwedToMe; // ئەگەر true بێت واتە قەرزم لای خەڵکە، ئەگەر false بێت واتە قەرز لەسەرمە
  final DateTime date;
  final String note;

  Debt({
    required this.id,
    required this.name,
    required this.amount,
    required this.isOwedToMe,
    required this.date,
    this.note = '',
  });
}
