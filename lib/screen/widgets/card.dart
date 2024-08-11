// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/currency.dart';
import '../../services/exchange_rate.dart';

class CardWidget extends StatelessWidget {
  final double balance;
  final Currency currency;
  final String accountNumber;

  // Ajoutez un constructeur pour initialiser le solde, la devise et le numéro de compte
  const CardWidget({
    Key? key,
    required this.balance,
    required this.currency,
    required this.accountNumber,
  }) : super(key: key);

  // Déplacez la déclaration de formatPrice en dehors de la méthode build
  String formatPrice(double price, Locale locale) {
    final format = NumberFormat("#,##0.00", locale.toString());
    return format.format(price);
  }

  @override
  Widget build(BuildContext context) {
    double convertedBalance;

    if (currency == Currency.USD) {
      convertedBalance = balance;
    } else {
      convertedBalance = ExchangeRate.convertFromUSD(balance, currency);
    }

    final formattedBalance =
        formatPrice(convertedBalance, Localizations.localeOf(context));

    String currencySymbol;
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

    String maskedAccountNumber = '';

    final RegExp regex = RegExp(r'[ -]+');
    final List<String> accountParts = accountNumber.split(regex);

    // Vérifier que la liste contient suffisamment d'éléments avant de tenter d'accéder aux éléments
    if (accountParts.length >= 4) {
      maskedAccountNumber =
          '${accountParts[0]} - **** - **** - ${accountParts[3]}';
      print('Masked Account Number: $maskedAccountNumber');
    } else {
      print('Invalid account number format');
    }

    // Affichage dans la console
    print('Account Number: $accountNumber');

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.deepOrange,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Total Balance',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Text(
              // Affiche le symbole de la devise avant ou après le solde en fonction de la devise

              currency == Currency.USD
                  ? '$currencySymbol ${formatPrice(balance, Localizations.localeOf(context))}'
                  : '$formattedBalance $currencySymbol',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Account Number',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 5),
                Column(
                  children: [
                    Text(
                      maskedAccountNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
