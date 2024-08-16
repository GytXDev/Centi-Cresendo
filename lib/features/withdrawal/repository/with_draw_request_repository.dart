// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/with_draw_request.dart';

class WithdrawRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<WithdrawalRequest>> getWithdrawalRequests(
      String userType, String userId) {
    try {
      // Deleting condition, all users can see withdrawal requests 
      return FirebaseFirestore.instance
          .collection('withdrawal_requests')
          .snapshots()
          .map((querySnapshot) => querySnapshot.docs
              .map((doc) => WithdrawalRequest.fromDocument(doc))
              .toList());
    } catch (e, stackTrace) {
      print('Erreur lors de la récupération des demandes de retrait: $e');
      print(stackTrace);
      return Stream.value([]);
    }
  }

  Future<void> deleteWithdrawalRequest(String requestId) async {
    try {
      await _firestore
          .collection('withdrawal_requests')
          .doc(requestId)
          .delete();
      print('Demande de retrait supprimée avec succès !');
    } catch (e) {
      print('Erreur lors de la suppression de la demande de retrait: $e');
      rethrow;
    }
  }

  // Méthode pour enregistrer une demande de retrait
  Future<void> saveWithdrawalRequest(WithdrawalRequest request) async {
    try {
      print('Envoi de la demande de retrait : $request');
      await FirebaseFirestore.instance
          .collection('withdrawal_requests')
          .doc(request.id)
          .set(request.toMap());
      print('Demande de retrait enregistrée avec succès !');
    } catch (e) {
      print('Erreur lors de l\'enregistrement de la demande de retrait: $e');
      rethrow;
    }
  }

  // Méthode pour mettre à jour le statut d'une demande de retrait
  Future<void> updateWithdrawalRequestStatus(
      String requestId, String status) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': status,
        'statusUpdateDate': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('withdrawal_requests')
          .doc(requestId)
          .update(updateData);
    } catch (e) {
      print(
          'Erreur lors de la mise à jour du statut de la demande de retrait: $e');
      rethrow;
    }
  }
}
