class Transaction {
  final int? id;
  final int itemId;
  final TransactionType type;
  final int quantity;
  final DateTime date;
  final String? supplier;
  final String? recipient;
  final String? notes;
  final int userId;

  Transaction({
    this.id,
    required this.itemId,
    required this.type,
    required this.quantity,
    required this.date,
    this.supplier,
    this.recipient,
    this.notes,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'supplier': supplier,
      'recipient': recipient,
      'notes': notes,
      'user_id': userId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id']?.toInt(),
      itemId: map['item_id']?.toInt() ?? 0,
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => TransactionType.incoming,
      ),
      quantity: map['quantity']?.toInt() ?? 0,
      date: DateTime.parse(map['date']),
      supplier: map['supplier'],
      recipient: map['recipient'],
      notes: map['notes'],
      userId: map['user_id']?.toInt() ?? 0,
    );
  }

  Transaction copyWith({
    int? id,
    int? itemId,
    TransactionType? type,
    int? quantity,
    DateTime? date,
    String? supplier,
    String? recipient,
    String? notes,
    int? userId,
  }) {
    return Transaction(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      supplier: supplier ?? this.supplier,
      recipient: recipient ?? this.recipient,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
    );
  }
}

enum TransactionType { incoming, outgoing }

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.incoming:
        return 'Barang Masuk';
      case TransactionType.outgoing:
        return 'Barang Keluar';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.incoming:
        return '➕';
      case TransactionType.outgoing:
        return '➖';
    }
  }
}
