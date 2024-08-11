import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../lang/app_translation.dart';
import '../../../models/bet_result.dart';
import '../../../models/user_model.dart';
import '../../../services/currency.dart';
import '../../../services/exchange_rate.dart';
import '../repository/bet_repository.dart';

Widget buildBetResultCard(
  BuildContext context,
  BetResultModel result,
  List<String> winnersNames,
  UserModel? user,
  Currency currency,
  WidgetRef ref,
) {
  double totalAmountWonInUSD = result.totalAmountWon;
  String currencySymbol = '';

  if (currency != Currency.USD) {
    totalAmountWonInUSD =
        ExchangeRate.convertFromUSD(totalAmountWonInUSD, currency);
    // ignore: avoid_print
    print('Montant après conversion : $totalAmountWonInUSD USD');
  }

  final totalAmountWonPerWinner = totalAmountWonInUSD / result.winners.length;
  final cardColor = Theme.of(context).brightness == Brightness.dark
      ? Colors.grey[800]
      : Colors.white;
  final textColor = Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : Colors.black;

  switch (currency) {
    case Currency.USD:
      currencySymbol = '\$';
      break;
    case Currency.Euro:
      currencySymbol = '€';
      break;
    case Currency.XAF:
      currencySymbol = 'XAF';
      break;
    case Currency.Rand:
      currencySymbol = 'Rand';
      break;
    case Currency.Naira:
      currencySymbol = '₦';
      break;
    case Currency.Dirham:
      currencySymbol = 'د.إ';
      break;
    case Currency.Shilling:
      currencySymbol = 'Ksh';
      break;
    case Currency.Kwacha:
      currencySymbol = 'ZMW';
      break;
    case Currency.Birr:
      currencySymbol = 'ETB';
      break;
    case Currency.Dinar:
      currencySymbol = 'د.ج';
      break;
    default:
      currencySymbol = '';
  }

  return Card(
    elevation: 3,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    color: cardColor,
    child: InkWell(
      onLongPress: () {
        if (user != null && user.userType == 'admin') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirmation de suppression"),
              content: const Text(
                  "Êtes-vous sûr de vouloir supprimer ce résultat de pari ?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(betRepositoryProvider)
                        .deleteBetResults(result.betId);
                    Navigator.pop(context);
                  },
                  child: const Text("Supprimer"),
                ),
              ],
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_events, // Icône de victoire
                  color: Colors.amber, // Couleur de l'icône de victoire
                ),
                const SizedBox(width: 8),
                Text(
                  'Gagnants',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: winnersNames
                  .map(
                    (name) => Row(
                      children: [
                        const Text(
                          '-',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(color: textColor, fontSize: 14.0),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$totalAmountWonPerWinner $currencySymbol',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            Divider(
              color: textColor,
              thickness: 0.5,
            ),
            const SizedBox(height: 8),
            Text(
              'Total de gain: $totalAmountWonInUSD $currencySymbol',
              style: TextStyle(color: textColor, fontSize: 15.0),
            ),
            const SizedBox(height: 16),
            Divider(
              color: textColor,
              thickness: 0.5, // Réduire l'épaisseur du Divider
            ),
            const SizedBox(height: 8),
            Text(
              _getMessageTimeString(result.dateSent, context),
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    ),
  );
}

String _getMessageTimeString(DateTime messageDate, BuildContext context) {
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime yesterday = today.subtract(const Duration(days: 1));
  DateTime aWeekAgo = today.subtract(const Duration(days: 7));
  String locale = Localizations.localeOf(context).languageCode;

  if (messageDate.isAfter(today)) {
    // Si le message a été envoyé aujourd'hui, retourne l'heure.
    return DateFormat('HH:mm', locale).format(messageDate);
  } else if (messageDate.isAfter(yesterday)) {
    // Si le message a été envoyé hier, retourne 'Hier'.
    return AppLocalizations.of(context).translate('yesterday');
  } else if (messageDate.isAfter(aWeekAgo)) {
    // Si le message a été envoyé au cours des 7 derniers jours, retourne le jour de la semaine.
    return DateFormat('EEEE', locale).format(messageDate);
  } else {
    // Pour les messages plus anciens, retourne la date complète.
    return DateFormat('dd/MM/yyyy', locale).format(messageDate);
  }
}
