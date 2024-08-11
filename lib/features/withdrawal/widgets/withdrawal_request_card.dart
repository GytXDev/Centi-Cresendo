// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:centi_cresento/services/currency.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import '../../../auth/repository/auth_repository.dart';
import '../../../colors/helpers/show_loading_dialog.dart';
import '../../../models/with_draw_request.dart';
import '../../../services/exchange_rate.dart';
import '../repository/with_draw_request_repository.dart';

class WithdrawalRequestCard extends StatelessWidget {
  final WithdrawalRequest withdrawalRequest;
  final bool showStatusButton;
  final authRepository = AuthRepository(
      auth: FirebaseAuth.instance, firestore: FirebaseFirestore.instance);
  final WithdrawRequestRepository _withDrawRepository =
      WithdrawRequestRepository();

  WithdrawalRequestCard({
    Key? key,
    required this.withdrawalRequest,
    this.showStatusButton = false,
  }) : super(key: key);

  void _deleteWithdrawalRequest(BuildContext context) async {
    if (withdrawalRequest.status == WithdrawalStatus.processed) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Suppression non autorisée',
        text: "Impossible d'annuler une demande traitée.",
      );
      return;
    }
    try {
      // Afficher une boîte de dialogue de confirmation pour la suppression
      final confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmation'),
          content: const Text(
              'Voulez-vous vraiment annuler cette demande vos fonds seront remboursés ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Annuler
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Confirmer
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );

      // Si l'utilisateur confirme la suppression
      if (confirmDelete == true) {
        double amountToAdd = withdrawalRequest.amount;
        if (withdrawalRequest.currency != 'USD' &&
            withdrawalRequest.currency == 'XAF') {
          amountToAdd = ExchangeRate.convertToUSD(amountToAdd, Currency.XAF);
          print('Montant après conversion : $amountToAdd USD');
        } else {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.warning,
            text:
                "La devise n'est pas prise en charge pour le type de transaction.",
          );
          return;
        }

        try {
          await authRepository.updateAdminBalance(
            amountToAdd: amountToAdd,
          );

          await _withDrawRepository
              .deleteWithdrawalRequest(withdrawalRequest.id);
        } catch (e) {
          print(e);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getStatusColor();
    String getStatusLabel(WithdrawalStatus status) {
      switch (status) {
        case WithdrawalStatus.processed:
          return 'Envoyée';
        case WithdrawalStatus.refused:
          return 'Annulée';
        case WithdrawalStatus.pending:
          return 'En cours';
        default:
          return 'Statut inconnu';
      }
    }

    return GestureDetector(
      onLongPress: () => _deleteWithdrawalRequest(context),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 48),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Référence:', withdrawalRequest.reference),
              _buildInfoRow(
                'Date de demande:',
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(withdrawalRequest.requestDate),
              ),
              _buildInfoRow(
                'Montant:',
                '${withdrawalRequest.amount} ${withdrawalRequest.currency}',
              ),
              if (withdrawalRequest.status == WithdrawalStatus.processed)
                Row(
                  children: [
                    _buildInfoRow(
                      '',
                      getStatusLabel(withdrawalRequest.status),
                      textColor: statusColor,
                    ),
                    const SizedBox(
                        width:
                            8), // Espacement entre le statut et la date de mise à jour
                    _buildProcessedStatusRow(context),
                  ],
                ),
              const SizedBox(height: 10),
              if (withdrawalRequest.status != WithdrawalStatus.processed)
                _buildInfoRow(
                  'Statut: ',
                  getStatusLabel(withdrawalRequest.status),
                  textColor: statusColor,
                ),
              _buildInfoRow(
                  'Numéro de téléphone:', withdrawalRequest.phoneNumber),
              const SizedBox(height: 10),
              if (showStatusButton &&
                  withdrawalRequest.status != WithdrawalStatus.processed)
                ElevatedButton(
                  onPressed: () => _showStatusDialog(context),
                  child: const Text(
                    'Changer le statut',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessedStatusRow(BuildContext context) {
    if (withdrawalRequest.statusUpdateDate != null) {
      final formattedDate = DateFormat('dd/MM/yyyy HH:mm')
          .format(withdrawalRequest.statusUpdateDate!);
      return _buildInfoRow('le :', formattedDate);
    } else {
      return _buildInfoRow(':', 'Inconnue');
    }
  }

  Color _getStatusColor() {
    switch (withdrawalRequest.status) {
      case WithdrawalStatus.pending:
        return Colors.orange;
      case WithdrawalStatus.processed:
        return Colors.green;
      case WithdrawalStatus.refused:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label $value',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _showStatusDialog(BuildContext context) async {
    WithdrawalStatus? newStatus = withdrawalRequest.status;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Changer le statut'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<WithdrawalStatus>(
                value: newStatus,
                onChanged: (value) {
                  setState(() {
                    newStatus = value;
                  });
                },
                items: WithdrawalStatus.values.map((status) {
                  return DropdownMenuItem<WithdrawalStatus>(
                    value: status,
                    child: Text(status.toString().split('.').last),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Annuler
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  showLoadingDialog(
                    context: context,
                    message: 'Changement de statut en cours',
                  );

                  await _withDrawRepository.updateWithdrawalRequestStatus(
                    withdrawalRequest.id,
                    newStatus.toString().split('.').last,
                  );

                  // Fermer la boîte de dialogue après avoir mis à jour le statut
                  Navigator.pop(context);

                  // Vérifier si le contexte est valide avant d'afficher l'alerte
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.success,
                    text: 'Statut mis à jour avec succès',
                  );
                } catch (e) {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Erreur',
                    text: 'Erreur lors de la mise à jour du statut',
                  );
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }
}
