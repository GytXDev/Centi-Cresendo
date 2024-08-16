// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:centi_cresento/features/withdrawal/repository/with_draw_request_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickalert/quickalert.dart';

import '../auth/controllers/auth_controller.dart';
import '../auth/repository/auth_repository.dart';
import '../colors/coloors.dart';
import '../colors/helpers/show_loading_dialog.dart';
import '../features/withdrawal/widgets/withdrawal_request_card.dart';
import '../models/user_model.dart';
import '../models/with_draw_request.dart';
import '../services/currency.dart';
import '../services/currency_determinate.dart';
import '../services/exchange_rate.dart';

class WithDrawal extends StatefulWidget {
  const WithDrawal({Key? key}) : super(key: key);

  @override
  State<WithDrawal> createState() => _WithDrawalState();
}

class _WithDrawalState extends State<WithDrawal> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final _withDrawRepository = WithdrawRequestRepository();
  late final UserModel user;
  final authRepository = AuthRepository(
      auth: FirebaseAuth.instance, firestore: FirebaseFirestore.instance);
  late Currency currency;
  String currencySymbol = '';
  bool isLoading = false;
  bool _isWithdrawalRequestsStreamInitialized = false;
  late final Stream<List<WithdrawalRequest>> withdrawalRequestsStream;

  // Méthode privée pour générer une réference aléatoire
  String generateRandomReference({int length = 6}) {
    const String characters =
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

    final Random random = Random();
    String result = '';

    for (int i = 0; i < length; i++) {
      result += characters[random.nextInt(characters.length)];
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
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

  // Méthode privée pour gérer la demande de retrait
  Future<void> _handleWithdrawalRequest() async {
    final phoneNumber = phoneNumberController.text;
    final amount = amountController.text.replaceAll(',', '.');

    // Vérifier si le numéro de téléphone contient uniquement des chiffres
    final RegExp numericPhoneRegex = RegExp(r'^[0-9]+$');
    if (!numericPhoneRegex.hasMatch(phoneNumber)) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'Le numéro de téléphone ne doit contenir que des chiffres.',
      );
      return;
    }

    // Vérifier si le montant contient uniquement des chiffres et des points décimaux
    final RegExp numericAmountRegex = RegExp(r'^[0-9.]+$');
    if (!numericAmountRegex.hasMatch(amount)) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text:
            'Le montant ne doit contenir que des chiffres et des points décimaux.',
      );
      return;
    }
    double amountInUSD = double.parse(amount);

    if (currency != Currency.USD) {
      amountInUSD = ExchangeRate.convertToUSD(amountInUSD, currency);
      print('Montant après conversion : $amountInUSD USD');
    }

    // Vérifier si la taille du numéro de téléphone est inférieure à 9 caractères
    if (phoneNumber.length < 9) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'Format du numéro de téléphone non valide.',
      );
      return;
    }
    // Vérifier si le montant est inférieur au montant minimal requis
    if (amountInUSD < 3.246) {
      double minimalAmountInUserCurrency =
          ExchangeRate.convertFromUSD(3.246, currency);

      // Arrondir le montant minimal requis au premier degré si la devise n'est pas USD
      if (currency != Currency.USD) {
        minimalAmountInUserCurrency =
            double.parse(minimalAmountInUserCurrency.toStringAsFixed(0));
      }

      QuickAlert.show(
        context: context,
        title: 'Avertissement!',
        type: QuickAlertType.warning,
        text:
            'Le montant minimal requis est de $minimalAmountInUserCurrency $currencySymbol dans votre devise.',
      );
      return; // Arrêter l'exécution du reste du code
    }
    try {
      setState(() {
        isLoading = true;
      });

      if (amountInUSD <= user.balance) {
        showLoadingDialog(
          context: context,
          message: 'Envoi de la requête en cours...',
          barrierDismissible: false,
        );
        final String reference = generateRandomReference(length: 6);
        print('Référence unique générée : $reference');

        final id = FirebaseFirestore.instance
            .collection('withdrawal_requests')
            .doc()
            .id;

        final newRequest = WithdrawalRequest(
          id: id,
          userId: user.uid,
          requestDate: DateTime.now(),
          phoneNumber: phoneNumber,
          amount: double.parse(amount),
          reference: reference,
          currency: currencySymbol,
        );

        print('Montant : $amount');
        print('Numéro de téléphone : $phoneNumber');
        print('Envoi de la demande de retrait : $newRequest');

        await _withDrawRepository.saveWithdrawalRequest(newRequest);

        final userModel = await authRepository.getCurrentUserInfo();
        if (userModel != null) {
          showLoadingDialog(
            context: context,
            message: 'Votre demande a réussi. Actualisation du solde...',
            barrierDismissible: false,
          );
          await authRepository.deductUserBalance(
            amountInUSD: amountInUSD,
            user: userModel,
          );

          // Fermer le dialogue de chargement après l'actualisation du solde
          Navigator.pop(context);

          setState(() {
            Navigator.pop(context);
          });

          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: 'Votre envoi de fonds est en cours ',
          );
        }
      } else {
        QuickAlert.show(
          title: 'Avertissement!',
          context: context,
          type: QuickAlertType.warning,
          text: 'Le montant demandé est supérieur à votre solde actuel.',
        );
      }
    } catch (e) {
      QuickAlert.show(
        title: 'Erreur!',
        context: context,
        type: QuickAlertType.error,
        text:
            'Une erreur s\'est produite lors du traitement de la demande de retrait.',
      );
      print('Erreur lors du traitement de la demande de retrait: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, WidgetRef ref, _) {
      final userModelAsyncValue = ref.watch(userProvider);

      return Scaffold(
        body: userModelAsyncValue.when(
          data: (userModel) {
            if (userModel == null) {
              return const Center(child: Text('No user found'));
            } else {
              final userType = userModel.userType;
              final uid = userModel.uid;
              if (!_isWithdrawalRequestsStreamInitialized) {
                withdrawalRequestsStream =
                    _withDrawRepository.getWithdrawalRequests(userType, uid);
                _isWithdrawalRequestsStreamInitialized = true;
              }
              return StreamBuilder<List<WithdrawalRequest>>(
                stream: withdrawalRequestsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/withdrawal.png',
                            width: 380,
                            height: 380,
                          ),
                          const Text(
                            'Aucune demande de retrait effectué',
                            style: TextStyle(
                              fontFamily: 'Crimson Text',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return WithdrawalRequestCard(
                                withdrawalRequest: snapshot.data![index],
                                showStatusButton: userType == 'admin',
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }
                },
              );
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  title: const Text(
                    'Retirer vos gains',
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: 'Permanent Marker',
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Montant',
                            prefixText: currencySymbol == '\$' ? '\$ ' : ' ',
                            suffix: SizedBox(
                              width: 48.0,
                              child: Text(
                                currencySymbol != '\$' ? currencySymbol : ' ',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            prefixStyle: const TextStyle(fontSize: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide:
                                  const BorderSide(color: Coolors.blueDark),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: phoneNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Numéro de réception',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide:
                                  const BorderSide(color: Coolors.blueDark),
                            ),
                          ),
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Annuler',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _handleWithdrawalRequest();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Coolors.blueDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: const Text('Valider',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(Icons.add),
        ),
      );
    });
  }
}

final userProvider = FutureProvider<UserModel?>((ref) {
  return ref.watch(authControllerProvider).getCurrentUserInfo();
});
