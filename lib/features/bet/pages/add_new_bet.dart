// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:centi_cresento/colors/helpers/show_loading_dialog.dart';
import 'package:centi_cresento/models/user_model.dart';
import 'package:centi_cresento/services/currency.dart';
import 'package:centi_cresento/services/currency_determinate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../auth/repository/auth_repository.dart';
import '../../../models/bet_model.dart';
import '../../../services/exchange_rate.dart';
import '../repository/bet_repository.dart';

class AddNewBet extends StatefulWidget {
  const AddNewBet({Key? key}) : super(key: key);

  @override
  State<AddNewBet> createState() => _AddNewBetState();
}

class _AddNewBetState extends State<AddNewBet> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _potentialGainController =
      TextEditingController();
  final TextEditingController _participationSumController =
      TextEditingController();
  Duration _selectedDuration = const Duration(days: 1);
  Duration _selectedAdditionalHours = Duration.zero;
  late final UserModel user;
  final _betRepository = BetRepository(
    firestore: FirebaseFirestore.instance,
  );
  final authRepository = AuthRepository(
      auth: FirebaseAuth.instance, firestore: FirebaseFirestore.instance);
  late Currency currency;
  String currencySymbol = '';

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _potentialGainController.dispose();
    _participationSumController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    try {
      final currentUser = await authRepository.getCurrentUserInfo();
      setState(() {
        user = currentUser!;
        currency =
            CurrencyService.determineCurrency(user.latitude, user.longitude);

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
      });
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur : $e');
    }
  }

  DateTime _calculateEndDate() {
    final now = DateTime.now();
    // Ajoutez la durée sélectionnée à la date et l'heure actuelles
    final endDate = now.add(_selectedDuration);
    // Ajoutez les heures supplémentaires à la date de fin
    final endDateWithHours = endDate.add(_selectedAdditionalHours);
    return endDateWithHours;
  }

  @override
  Widget build(BuildContext context) {
    final endDate = _calculateEndDate();
    final endDateFormatted =
        '${endDate.day}/${endDate.month}/${endDate.year} à ${endDate.hour}h${endDate.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle opportunité'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _participationSumController,
              decoration: InputDecoration(
                labelText: 'Somme de participation',
                prefixText: currencySymbol == '\$' ? '' : ' ',
                suffix: SizedBox(
                  width: 48.0,
                  child: Text(
                    currencySymbol != '\$' ? currencySymbol : ' ',
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _potentialGainController,
              decoration: InputDecoration(
                labelText: 'Gain potentiel',
                prefixText: currencySymbol == '\$' ? '' : ' ',
                suffix: SizedBox(
                  width: 48.0,
                  child: Text(
                    currencySymbol != '\$' ? currencySymbol : ' ',
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Duration>(
              value: _selectedDuration,
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value!;
                });
              },
              items: const [
                DropdownMenuItem(
                  value: Duration(days: 1),
                  child: Text('1 jour'),
                ),
                DropdownMenuItem(
                  value: Duration(days: 2),
                  child: Text('2 jours'),
                ),
                DropdownMenuItem(
                  value: Duration(days: 3),
                  child: Text('3 jours'),
                ),
                DropdownMenuItem(
                  value: Duration(days: 4),
                  child: Text('4 jours'),
                ),
                DropdownMenuItem(
                  value: Duration(days: 5),
                  child: Text('5 jours'),
                ),
                DropdownMenuItem(
                  value: Duration(days: 6),
                  child: Text('6 jours'),
                ),
                DropdownMenuItem(
                  value: Duration(days: 7),
                  child: Text('1 semaine'),
                ),
              ],
              decoration: const InputDecoration(
                labelText: 'Durée',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Duration>(
              value: _selectedAdditionalHours,
              onChanged: (value) {
                setState(() {
                  _selectedAdditionalHours = value!;
                });
              },
              items: [
                const DropdownMenuItem(
                  value: Duration.zero,
                  child: Text('Aucune heure supplémentaire'),
                ),
                ...List.generate(24, (index) {
                  return DropdownMenuItem(
                    value: Duration(hours: index + 1),
                    child:
                        Text('${index + 1} heure${(index + 1) > 1 ? 's' : ''}'),
                  );
                }).toList(),
              ],
              decoration: const InputDecoration(
                labelText: 'Heures supplémentaires',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Date et heure de fin estimées : $endDateFormatted',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                double potentialGainInUSD =
                    double.parse(_potentialGainController.text);
                if (currency != Currency.USD) {
                  potentialGainInUSD =
                      ExchangeRate.convertToUSD(potentialGainInUSD, currency);
                  print(
                      'Montant de gain après conversion : $potentialGainInUSD USD');
                }

                double participationSumInUSD =
                    double.parse(_participationSumController.text);
                if (currency != Currency.USD) {
                  participationSumInUSD = ExchangeRate.convertToUSD(
                      participationSumInUSD, currency);
                  print(
                      'Montant de participation après conversion : $participationSumInUSD USD');
                }
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  try {
                    showLoadingDialog(
                      context: context,
                      message: 'Saving bet',
                      barrierDismissible: false,
                    );
                    final id =
                        FirebaseFirestore.instance.collection('bets').doc().id;
                    final newBet = BetModel(
                      id: id,
                      userId: currentUser.uid,
                      description: _descriptionController.text,
                      potentialGain: potentialGainInUSD,
                      participationSum: participationSumInUSD,
                      participants: [],
                      winners: [],
                      creationDate: DateTime.now(),
                      duration: _selectedDuration + _selectedAdditionalHours,
                      // Note : endDate n'est pas inclus ici
                    );
                    await _betRepository.addBet(newBet);
                    Navigator.pop(context);
                    // Fermer la page après l'enregistrement
                    setState(() {
                      Navigator.pop(context);
                    });
                  } catch (e) {
                    print(e);
                  }
                } else {
                  print('Aucun utilisateur connecté');
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
