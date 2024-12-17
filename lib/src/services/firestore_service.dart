import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add an appointment
  Future<void> addAppointment(Map<String, dynamic> data) async {
    await _firestore.collection('appointments').add(data);
  }

  // Delete an appointment
  Future<void> deleteAppointment(String docId) async {
    await _firestore.collection('appointments').doc(docId).delete();
  }

  // Update an appointment
  Future<void> updateAppointment(
      String docId, Map<String, dynamic> data) async {
    await _firestore.collection('appointments').doc(docId).update(data);
  }

  // Get all appointments
  Stream<QuerySnapshot> getAllAppointments() {
    return _firestore
        .collection('appointments')
        .orderBy('date', descending: false)
        .snapshots();
  }
}
