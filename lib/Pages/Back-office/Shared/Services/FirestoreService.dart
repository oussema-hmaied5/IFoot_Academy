// ignore: file_names
// ignore_for_file: file_names, duplicate_ignore

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a document from a specific collection by its ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collection,
    required String docId,
  }) async {
    return await _firestore.collection(collection).doc(docId).get();
  }

  /// Add a new document to a collection
  Future<DocumentReference> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    return await _firestore.collection(collection).add(data);
  }

  /// Update a document in a specific collection by its ID
  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    return await _firestore.collection(collection).doc(docId).update(data);
  }

  /// Delete a document from a collection by its ID
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    return await _firestore.collection(collection).doc(docId).delete();
  }

  /// Get a stream of documents for real-time updates
  Stream<QuerySnapshot<Map<String, dynamic>>> getCollectionStream({
    required String collection,
  }) {
    return _firestore.collection(collection).snapshots();
  }

  /// Get all documents from a collection as a list
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getCollection({
    required String collection,
  }) async {
    final snapshot = await _firestore.collection(collection).get();
    return snapshot.docs;
  }
}
