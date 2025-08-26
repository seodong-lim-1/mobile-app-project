import 'package:cloud_firestore/cloud_firestore.dart';

class Entry {
  String? id;
  String? description;
  String? date;
  String? category;
  double? amount;

  // Constructor
  Entry({
    this.id,
    required this.description,
    required this.date,
    required this.category,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'date': date,
      'category': category,
      'amount': amount,
    };
  }

  factory Entry.fromFirestore(DocumentSnapshot document) {
    final Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    final String documentId = document.id;

    // Handle 'amount' conversion to double
    final double amount = (data['amount'] ?? 0).toDouble();

    return Entry(
      id: documentId,
      description: data['description'],
      date: data['date'],
      category: data['category'],
      amount: amount,
    );
  }

  factory Entry.fromDatabase(Map<String, dynamic> map) {
    return Entry(
      id: map['id'].toString(),
      description: map['description'],
      date: map['date'],
      category: map['category'],
      amount: map['amount'],
    );
  }

  Entry.fromMap(Map map) {
    this.id = map['id'];
    this.description = map['description'];
    this.date = map['date'];
    this.category = map['category'];
    this.amount = map['amount'];
  }

  @override
  String toString() {
    return 'id: $id, description: $description, date: $date, category: $category, amount: $amount';
  }
}
