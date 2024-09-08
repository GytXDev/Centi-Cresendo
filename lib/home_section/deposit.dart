// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:centi_cresento/colors/coloors.dart';
import 'package:centi_cresento/colors/extension/extension_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';

import '../auth/repository/auth_repository.dart';
import '../colors/helpers/show_loading_dialog.dart';
import '../features/deposit/helpers/message_type.dart';
import '../models/user_model.dart';
import '../services/currency.dart';
import '../services/currency_determinate.dart';
import '../services/exchange_rate.dart';

class Deposit extends StatefulWidget {
  const Deposit({Key? key}) : super(key: key);

  @override
  State<Deposit> createState() => _DepositState();
}

class _DepositState extends State<Deposit> {
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final authRepository = AuthRepository(
      auth: FirebaseAuth.instance, firestore: FirebaseFirestore.instance);
  late final UserModel user;
  late Currency currency;
  String currencySymbol = '';
  bool isLoading = false;
  final ScrollController scrollerControntroller = ScrollController();
  final FocusNode phoneNumberFocus = FocusNode();
  final FocusNode amountFocus = FocusNode();
  bool isPhoneNumberFieldSelected = false;

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

        // Mettre à jour currencySymbol en fonction de la devise
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

  Future<void> _depositMoney() async {
    final phoneNumber = phoneNumberController.text;
    final amount = amountController.text.replaceAll(',', '.');

    // Vérifier si l'utilisateur est un administrateur
    if (user.userType == 'admin') {
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

      double amountToAdd = double.parse(amount);
      if (currency != Currency.USD && currency == Currency.XAF) {
        amountToAdd = ExchangeRate.convertToUSD(amountToAdd, currency);
        print('Montant après conversion : $amountToAdd USD');
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          text:
              "La devise $currencySymbol n'est pas prise en charge pour le type de transaction.",
        );
        return;
      }

      try {
        setState(() {
          isLoading = true;
        });
        showLoadingDialog(
          context: context,
          message: 'Envoi de la requête en cours...',
          barrierDismissible: false,
        );

        // Obtenir les informations de l'utilisateur connecté
        UserModel? userModel = await authRepository.getCurrentUserInfo();
        if (userModel == null) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            text:
                'Impossible de récupérer les informations de l\'administrateur.',
          );
          setState(() {
            isLoading = false;
          });
          return;
        }

        // Recharger directement le compte de l'administrateur sans passer par l'API
        await authRepository.updateBalance(
          amountToAdd: amountToAdd,
          user: userModel,
        );
        Navigator.pop(context);
        // Afficher une alerte pour informer l'utilisateur de l'action effectuée
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'Votre compte a été rechargé avec succès.',
        );

        // Vider les contrôleurs de texte après un dépôt réussi
        phoneNumberController.clear();
        amountController.clear();

        // Mettre à jour l'état de chargement
        setState(() {
          isLoading = false;
        });
        return;
      } catch (e) {
        print(e);
      }
    }

    String url;

    // Vérifier le préfixe du numéro de téléphone pour la redirection
    if (phoneNumber.startsWith('074') ||
        phoneNumber.startsWith('077') ||
        phoneNumber.startsWith('076') ||
        phoneNumber.startsWith('075')) {
      url = 'https://centicresento.com/api/airtelmoney.php';
    } else if (phoneNumber.startsWith('060') ||
        phoneNumber.startsWith('062') ||
        phoneNumber.startsWith('066') ||
        phoneNumber.startsWith('060')) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text:
            'Veuillez nous excuser, le service de paiement via Moov Money est temporairement indisponible.',
      );
      return;
      //url = 'https://centicresento.com/api/moovmoney.php';
    } else {
      // Redirection par défaut si aucun préfixe ne correspond
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text:
            'Aucune redirection disponible pour ce préfixe de numéro de téléphone.',
      );
      return;
    }

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

    double amountToAdd = double.parse(amount);

    // Convertir le montant si la devise de l'utilisateur n'est pas USD
    if (currency != Currency.USD && currency == Currency.XAF) {
      amountToAdd = ExchangeRate.convertToUSD(amountToAdd, currency);
      print('Montant après conversion : $amountToAdd USD');
    } else {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text:
            "La devise $currencySymbol n'est pas prise en charge pour le type de transaction.",
      );
      return;
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
    if (amountToAdd < 0.162) {
      double minimalAmountInUserCurrency =
          ExchangeRate.convertFromUSD(0.162, currency);

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
      showLoadingDialog(
        context: context,
        message: 'Envoi de la requête en cours...',
        barrierDismissible: false,
      );

      final response = await http.post(
        Uri.parse(url),
        body: {'numero': phoneNumber, 'amount': amount},
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final phpResponseMessage = response.headers['x-php-response-message'];

        print('Message de réponse PHP : $phpResponseMessage');

        if (phpResponseMessage != null && phpResponseMessage.isNotEmpty) {
          final messageType = identifyMessageType(phpResponseMessage);

          switch (messageType) {
            case MessageType.SuccessfulTransaction:
              final userModel = await authRepository.getCurrentUserInfo();
              if (userModel != null) {
                showLoadingDialog(
                  context: context,
                  message:
                      'Votre transaction a réussi. Actualisation du solde...',
                  barrierDismissible: false,
                );
                await authRepository.updateUserBalance(
                  user: userModel,
                  amountToAdd: amountToAdd,
                  phoneNumber: phoneNumber,
                );

                // Fermer le dialogue de chargement après l'actualisation du solde
                Navigator.pop(context);

                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  text: phpResponseMessage,
                );

                // Vider les contrôleurs de texte après un dépôt réussi
                phoneNumberController.clear();
                amountController.clear();
                break;
              }
              break;
            case MessageType.UnableToGetTransactionStatus:
              QuickAlert.show(
                context: context,
                type: QuickAlertType.warning,
                text: phpResponseMessage,
              );
              break;
            case MessageType.InvalidPinLength:
              QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                text: phpResponseMessage,
              );
              break;
            case MessageType.InsufficientBalance:
              QuickAlert.show(
                context: context,
                type: QuickAlertType.warning,
                text: phpResponseMessage,
              );
              break;
            case MessageType.IncorrectPin:
              QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                text: phpResponseMessage,
              );
              break;
            case MessageType.CancelledTransaction:
              QuickAlert.show(
                context: context,
                type: QuickAlertType.info,
                text: phpResponseMessage,
              );
            case MessageType.Other:
              QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                text: phpResponseMessage,
              );
              break;
          }
        } else {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.info,
            text: 'Vous avez peut-être annulé l\'action.',
          );
        }
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Erreur',
          text: 'La requête a échoué avec le code ${response.statusCode}.',
        );
      }
    } catch (e) {
      Navigator.pop(context); // Ferme le dialogue de chargement en cas d'erreur
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Erreur',
        text: 'Une erreur est survenue lors du traitement de la requête.',
      );
      print(e);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _removeTransactionNumber(String number) async {
    setState(() {
      user.removeTransactionNumber(number);
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update(user.toMap());
  }

  // Méthode pour récupérer les suggestions de numéro de téléphone basées sur transactionNumbers
  List<String>? getSuggestions() {
    return user.transactionNumbers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 72.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Pour jouer, rechargez votre compte Centi Crescendo via Airtel Money ou Moov Money, achetez votre ticket et tentez votre chance !',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  fontSize: 18.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: phoneNumberController,
                      keyboardType: TextInputType.phone,
                      focusNode: phoneNumberFocus,
                      decoration: InputDecoration(
                        labelText:
                            'Numéro de téléphone ( Moov Money/ Airtel Money )',
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Coolors.blueDark),
                        ),
                        labelStyle: TextStyle(
                          color: phoneNumberFocus.hasFocus
                              ? Colors.blue
                              : Coolors.greyLight,
                        ),
                        suffixIcon: phoneNumberController.text.isNotEmpty
                            ? Container(
                                margin: const EdgeInsets.only(
                                    right: 18.0, top: 8.0),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size:
                                        16.0, // Réduction de la taille de l'icône
                                  ),
                                  onPressed: () {
                                    phoneNumberController.clear();
                                    setState(() {
                                      isPhoneNumberFieldSelected = false;
                                    });
                                  },
                                ),
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          isPhoneNumberFieldSelected = value.isNotEmpty;
                        });
                      },
                      onTap: () {
                        setState(() {
                          isPhoneNumberFieldSelected = true;
                        });
                        _scrollTo(context, phoneNumberFocus);
                      },
                    ),

                    // Liste déroulante pour afficher les suggestions
                    if (isPhoneNumberFieldSelected &&
                        getSuggestions() != null &&
                        getSuggestions()!.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: getSuggestions()!.length,
                        itemBuilder: (context, index) {
                          final suggestion = getSuggestions()![index];
                          return Card(
                            color: Colors.white,
                            elevation: 4.0,
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text(
                                suggestion,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                  color: context.theme.blackText,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () =>
                                    _removeTransactionNumber(suggestion),
                              ),
                              onTap: () {
                                setState(() {
                                  phoneNumberController.text = suggestion;
                                  isPhoneNumberFieldSelected = false;
                                });
                              },
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 16.0),
                    TextField(
                      controller: amountController,
                      focusNode: amountFocus,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Montant à déposer',
                        prefixText: currencySymbol == '\$' ? '\$' : ' ',
                        labelStyle: TextStyle(
                          color: amountFocus.hasFocus
                              ? Colors.blue
                              : Coolors.greyLight,
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Coolors.blueDark),
                        ),
                        suffix: SizedBox(
                          width: 48.0,
                          child: Text(
                            currencySymbol != '\$' ? currencySymbol : ' ',
                            style: const TextStyle(color: Coolors.greyLight),
                          ),
                        ),
                        prefixStyle: const TextStyle(color: Coolors.greyLight),
                      ),
                      onTap: () {
                        _scrollTo(context, amountFocus);
                      },
                    ),
                    const SizedBox(height: 34.0),
                    ElevatedButton(
                      onPressed: () {
                        // Vérifier si les champs sont remplis avant de déposer de l'argent
                        if (phoneNumberController.text.isEmpty ||
                            amountController.text.isEmpty) {
                          QuickAlert.show(
                            title: 'Avertissement!',
                            context: context,
                            type: QuickAlertType.warning,
                            text: 'Veuillez remplir tous les champs.',
                          );
                        } else {
                          _depositMoney(); // Déposer de l'argent si les champs sont remplis
                        }
                      },
                      // Désactiver le bouton pendant le chargement
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16.0),
                        backgroundColor:
                            isLoading ? Colors.grey : Coolors.purpleDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text(
                        'Déposer de l\'argent',
                        style: TextStyle(fontSize: 14.0, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 14.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollTo(BuildContext context, FocusNode focusNode) {
    // Scroll to the focused field
    Scrollable.ensureVisible(focusNode.context!,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }
}
