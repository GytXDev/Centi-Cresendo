// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/bet_model.dart';
import '../../../models/bet_result.dart';

final betRepositoryProvider = Provider((ref) {
  return BetRepository(
    firestore: FirebaseFirestore.instance,
  );
});

class BetRepository {
  final FirebaseFirestore firestore;

  BetRepository({required this.firestore});

  Future<void> addBet(BetModel bet) async {
    try {
      await firestore.collection('bets').doc(bet.id).set(bet.toMap());
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de l\'ajout du pari: $e');
      rethrow;
    }
  }

  // Ajoutez cette méthode pour récupérer les paris depuis Firebase Firestore
  Stream<List<BetModel>> getBets() {
    try {
      return firestore.collection('bets').snapshots().map((querySnapshot) =>
          querySnapshot.docs
              .map((doc) => BetModel.fromMap(doc.data()))
              .toList());
    } catch (e, stackTrace) {
      print('Erreur lors de la récupération des paris: $e');
      print(stackTrace);
      // Vous pouvez choisir de renvoyer un flux vide ou de lever l'erreur
      // throw e;
      return Stream.value([]);
    }
  }

  /// Met à jour la liste des participants pour un pari donné.
  Future<void> updateBetParticipants(
      String betId, List<String> participants) async {
    try {
      await firestore.collection('bets').doc(betId).update({
        'participants': participants,
      });
    } catch (e) {
      print('Erreur lors de la mise à jour des participants du pari: $e');
      rethrow;
    }
  }

  // Ajoute les vainqueurs sélectionnés au pari
  Future<void> addWinners(List<String> winners, String betId) async {
    try {
      await firestore.collection('bets').doc(betId).update({
        'winners': winners,
      });
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de l\'ajout des vainqueurs: $e');
      rethrow;
    }
  }

  // Ajoutez cette méthode pour récupérer les résultats des paris depuis Firebase Firestore
  Stream<List<BetResultModel>> getBetResults() {
    try {
      return firestore.collection('bet_results').snapshots().map(
          (querySnapshot) => querySnapshot.docs
              .map((doc) => BetResultModel.fromMap(doc.data()))
              .toList());
    } catch (e, stackTrace) {
      print('Erreur lors de la récupération des résultats des paris: $e');
      print(stackTrace);
      // Vous pouvez choisir de renvoyer un flux vide ou de lever l'erreur
      // throw e;
      return Stream.value([]);
    }
  }

  // Inscription d'un participant
  Future<void> addParticipant(String userId, String betId) async {
    try {
      await firestore.collection('bets').doc(betId).update({
        'participants': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de l\'ajout du participant: $e');
      rethrow;
    }
  }

  // Mettre à jour le champ isGainSending dans Firestore
  Future<void> updateIsGainSending(String betId, bool isSending) async {
    try {
      await firestore.collection('bets').doc(betId).update({
        'isGainSending': isSending,
      });
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de la mise à jour de isGainSending: $e');
      rethrow;
    }
  }

  // Mise à jour des tickets de l'utilisateur
  Future<void> updateUserTickets(String userId, List<String> ticketIds) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'ticketIds': ticketIds,
      });
    } catch (e) {
      print('Erreur lors de la mise à jour des tickets de l\'utilisateur: $e');
      rethrow;
    }
  }

  // Méthode pour supprimer un pari
  Future<void> deleteBet(String betId) async {
    try {
      await firestore.collection('bets').doc(betId).delete();
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de la suppression du pari: $e');
      rethrow;
    }
  }

  // Méthode pour supprimer les résultats d'un pari
  Future<void> deleteBetResults(String betId) async {
    try {
      await firestore.collection('bet_results').doc(betId).delete();
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de la suppression des résultats du pari: $e');
      rethrow;
    }
  }
}
