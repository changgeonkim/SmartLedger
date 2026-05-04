import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get expenses =>
      _db.collection('expenses');

  CollectionReference<Map<String, dynamic>> get categories =>
      _db.collection('categories');

  CollectionReference<Map<String, dynamic>> get budgets =>
      _db.collection('budgets');
}
