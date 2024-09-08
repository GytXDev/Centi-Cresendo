// ignore_for_file: use_build_context_synchronously, avoid_print, library_private_types_in_public_api

import 'dart:math';

import 'package:centi_cresento/colors/coloors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'dart:async';

import '../../../auth/repository/auth_repository.dart';
import '../../../colors/helpers/show_loading_dialog.dart';
import '../../../models/bet_model.dart';
import '../../../models/user_model.dart';
import '../../../services/currency.dart';
import '../../../services/exchange_rate.dart';
import '../repository/bet_repository.dart';

class BetListWidget extends StatefulWidget {
  final Stream<List<BetModel>> stream;
  final Currency currency;

  const BetListWidget({Key? key, required this.stream, required this.currency})
      : super(key: key);

  @override
  _BetListWidgetState createState() => _BetListWidgetState();
}

class _BetListWidgetState extends State<BetListWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  late Duration _remainingTime;

  UserModel? currentUser;

  bool isUserRegistered = false;

  bool isMounted = false;
  bool isLoading = false;

  final BetRepository _betRepository =
      BetRepository(firestore: FirebaseFirestore.instance);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );

    _remainingTime = const Duration(seconds: 60);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime = _remainingTime - const Duration(seconds: 1);
      });
    });

    getCurrentUser().then((user) {
      if (mounted) {
        setState(() {
          currentUser = user;
        });
      }
    });

    isMounted = true;
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return getUserData(user.uid);
      }
      return null;
    } catch (e) {
      print("Error retrieving current user : $e");
      return null;
    }
  }

  Widget _buildParticipationButton(
    BuildContext context,
    BetModel bet,
    UserModel? currentUser,
  ) {
    // Vérifiez si l'utilisateur est déjà inscrit en comparant son ID avec la liste des participants
    bool isUserParticipant = bet.participants
        .any((participant) => participant.startsWith('${currentUser?.uid}_'));
    double convertedPotentialGain;

    String currencySymbol;
    switch (widget.currency) {
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

    if (widget.currency == Currency.USD) {
      convertedPotentialGain = bet.potentialGain;
    } else {
      convertedPotentialGain =
          ExchangeRate.convertFromUSD(bet.potentialGain, widget.currency);
    }
    final formattedPotentialGain =
        formatPrice(convertedPotentialGain, Localizations.localeOf(context));
    final remainingTime =
        bet.creationDate.add(bet.duration).difference(DateTime.now());

    if (isUserParticipant) {
      // Vérifie si l'utilisateur est un gagnant
      bool isWinner = bet.winners.contains(currentUser?.uid ?? '');

      if (isWinner) {
        // Si l'utilisateur est un gagnant, affichez "Félicitations gain du pari" avec une icône d'étoile
        if (remainingTime.inMinutes < 0 &&
            remainingTime.inHours < 30 &&
            bet.winners.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow),
                const SizedBox(width: 8),
                if (currentUser != null && currentUser.userType == 'user')
                  Row(
                    children: [
                      const Text('Félicitations !'),
                      const SizedBox(width: 6),
                      Text(
                        widget.currency == Currency.USD
                            ? '$currencySymbol $formattedPotentialGain'
                            : '$formattedPotentialGain $currencySymbol',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }
      }

      if (remainingTime.inMinutes <= 0) {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '🎯 Continuez à tenter votre chance, le prochain ticket sera le bon !',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      } else {
        // Calculer le nombre total de tickets achetés par l'utilisateur pour ce pari
        int ticketCount = bet.participants
            .where(
                (participant) => participant.startsWith('${currentUser?.uid}_'))
            .length;

        // Vérifiez si la participation est gratuite et s'il y a des tickets achetés
        bool isFreeTicket = bet.participationSum == 0;
        if (isFreeTicket) {
          // Si le ticket est gratuit, afficher le bouton désactivé avec un texte approprié
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ElevatedButton(
              onPressed: null, // Le bouton est désactivé
              style: ElevatedButton.styleFrom(
                backgroundColor: Coolors.blueDark,
              ),
              child: const Text(
                'Participation gratuite !',
                style: TextStyle(color: Coolors.blueDark),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: remainingTime.inHours >= 1
              ? ElevatedButton(
                  onPressed: () {
                    _showParticipationDialog(context, bet);
                  },
                  child: Text(
                    'Augmenter vos chances ($ticketCount ticket${ticketCount > 1 ? 's' : ''})',
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : SizedBox.shrink(), // Affiche rien si le temps est écoulé
        );
      }
    } else {
      // Sinon, affichez le bouton "Participer"
      if (currentUser != null && currentUser.userType == 'user') {
        return Visibility(
          visible: remainingTime.inHours >= 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ElevatedButton(
              onPressed: () {
                _showParticipationDialog(context, bet);
              },
              child: const Text(
                'Acheter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> updateBalance(double newBalance) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .update({'balance': newBalance});
  }

  Future<UserModel> getUserData(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    UserModel user = UserModel.fromMap(userDoc.data()!);
    print('User data retrieved: $user');
    return user;
  }

  String formatPrice(double price, Locale locale) {
    final format = NumberFormat(
        "#,##0", locale.toString()); // Pas de chiffres après la virgule
    return format.format(price);
  }

  void _showChooseWinnersDialog(BuildContext context, BetModel bet) {
    int numberOfParticipants = bet.participants.length;
    int? numberOfWinners;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir les gagnants'),
          content: TextFormField(
            decoration: const InputDecoration(labelText: 'Nombre de gagnants'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nombre';
              }
              int parsedValue = int.tryParse(value)!;
              if (parsedValue <= 0) {
                return 'Veuillez entrer un nombre valide';
              }
              if (parsedValue > numberOfParticipants) {
                return 'Le nombre de gagnants ne peut pas dépasser le nombre de participants';
              }
              return null;
            },
            onChanged: (value) {
              numberOfWinners = int.tryParse(value);
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (numberOfWinners != null &&
                    numberOfWinners! <= numberOfParticipants) {
                  try {
                    showLoadingDialog(
                      context: context,
                      message: 'Tirage au sort en cours...',
                    );
                    setState(() {
                      List<String> winners =
                          selectWinners(bet.participants, numberOfWinners!);

                      // Extraire les IDs utilisateur avant le caractère '_'
                      winners.map((winner) {
                        final parts = winner.split('_');
                        return parts[0];
                      }).toList();

                      // Assurez-vous que la liste des gagnants accepte les doublons
                      List<String> winnersWithDuplicates = [];
                      for (var winner in winners) {
                        final parts = winner.split('_');
                        winnersWithDuplicates.add(parts[0]);
                      }

                      _betRepository.addWinners(winnersWithDuplicates, bet.id);
                      Navigator.of(context).pop();
                    });
                    _showSuccessAlertWinners(context);
                  } catch (e) {
                    print(e);
                    _showErrorAlertWinner(context);
                  }
                } else {
                  // Afficher un message d'erreur
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Erreur',
                    text:
                        'Le nombre de gagnants ne peut pas dépasser le nombre de participants.',
                  );
                }
              },
              child: const Text('Tirer au sort'),
            ),
          ],
        );
      },
    );
  }

  List<String> selectWinners(List<String> participants, int numberOfWinners) {
    List<String> winners = [];

    Set<int> selectedIndices = {};
    Random random = Random();

    while (winners.length < numberOfWinners) {
      int selectedIndex = random.nextInt(participants.length);
      if (!selectedIndices.contains(selectedIndex)) {
        winners.add(participants[selectedIndex]);
        selectedIndices.add(selectedIndex);
      }
    }

    return winners;
  }

  void _showSuccessAlertWinners(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: 'Nombre de vainqueur!',
    );
  }

  void _showErrorAlertWinner(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Erreur',
      text: 'Erreur lors de l\'ajout des vainqueurs au pari',
    );
  }

  void _sendGainsToWinners(
    BuildContext context,
    BetModel bet,
    AuthRepository authRepository,
  ) {
    setState(() {
      isLoading = true;
    });
    double amountPerWinner = 0.0;

    if (currentUser == null) {
      // Gérer le cas où currentUser est null
      print('Erreur: currentUser est null.');
      return;
    }

    String currencySymbol;
    switch (widget.currency) {
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Saisir le montant par gagnant'),
              content: TextFormField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Montant par gagnant',
                  prefixText: currencySymbol == '\$' ? '' : ' ',
                  suffix: SizedBox(
                    width: 48.0,
                    child: Text(
                      currencySymbol != '\$' ? currencySymbol : ' ',
                      style: const TextStyle(color: Coolors.greyLight),
                    ),
                  ),
                  prefixStyle: const TextStyle(color: Coolors.greyLight),
                ),
                onChanged: (value) {
                  setState(() {
                    amountPerWinner = double.tryParse(value) ?? 0.0;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un montant par gagnant.';
                  }
                  return null;
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    showLoadingDialog(
                      context: context,
                      message: 'Envoi des gains',
                      barrierDismissible: false,
                    );
                    if (amountPerWinner <= 0.0) {
                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.error,
                        title: 'Montant invalide',
                        text: 'Veuillez saisir un montant valide par gagnant.',
                      );
                      return;
                    }

                    double totalGains = amountPerWinner * bet.winners.length;
                    double amountInUSD = amountPerWinner;
                    if (widget.currency != Currency.USD) {
                      amountInUSD = ExchangeRate.convertToUSD(
                          amountInUSD, widget.currency);
                      print('Montant après conversion : $amountInUSD USD');
                    }
                    double totalGainsInUSD = totalGains;
                    if (widget.currency != Currency.USD) {
                      totalGainsInUSD = ExchangeRate.convertToUSD(
                          totalGainsInUSD, widget.currency);
                      print('Montant après conversion : $totalGainsInUSD USD');
                    }

                    if (totalGainsInUSD > currentUser!.balance) {
                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.error,
                        title: 'Solde insuffisant',
                        text: 'Solde insuffisant pour transférer les gains.',
                      );
                      return;
                    }

                    for (String winnerId in bet.winners) {
                      try {
                        UserModel? winner =
                            await authRepository.getUserByUid(winnerId);

                        if (winner != null) {
                          // Utilisateur trouvé, envoyer les gains
                          await authRepository.sendGainsToWinners(
                            user: winner,
                            amountToAdd: amountInUSD,
                            betId: bet.id,
                            winners: bet.winners,
                          );
                          await authRepository.reducAdminBalance(
                            amountToAdd: amountInUSD,
                          );

                          setState(() {
                            // Ne pop pas le contexte ici
                          });
                        } else {
                          // Utilisateur introuvable, afficher une alerte
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.error,
                            text: 'Utilisateur $winnerId introuvable.',
                          );
                        }
                      } catch (e) {
                        // Gérer l'erreur
                        print(
                            'Erreur lors de l\'envoi des gains à $winnerId: $e');
                      }
                    }
                    // Fermer le dialogue de chargement après l'actualisation du solde
                    Navigator.pop(context);
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.success,
                      text: 'Gains envoyés avec succès à tout les gagnants.',
                    );
                  },
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Mise à jour des tickets de l'utilisateur
  Future<void> updateUserTickets(String userId, List<String> ticketIds) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'ticketIds': ticketIds,
      });
    } catch (e) {
      print('Erreur lors de la mise à jour des tickets de l\'utilisateur: $e');
      rethrow;
    }
  }

  Future<String?> _participationText(BuildContext context, BetModel bet) async {
    final UserModel? currentUser = await getCurrentUser();

    // Si l'utilisateur n'est pas connecté, on ne fait rien
    if (currentUser == null) return null;

    // Détermine combien de tickets l'utilisateur a achetés pour ce pari
    int userTicketsCountForCurrentBet = bet.participants
        .where((participant) => participant.startsWith('${currentUser.uid}_'))
        .length;

    // Génère un message si l'utilisateur a acheté des tickets
    if (userTicketsCountForCurrentBet > 0) {
      final ticketText = userTicketsCountForCurrentBet == 1
          ? '1 ticket'
          : '${userTicketsCountForCurrentBet} tickets';
      final successMessage = 'Participation enregistrée : $ticketText';
      return successMessage;
    }
    return null;
  }

  //Dialogue d'achat
  void _showParticipationDialog(BuildContext context, BetModel bet) async {
    final UserModel? currentUser = await getCurrentUser();

    if (currentUser == null) return;

    // Déterminez combien de tickets l'utilisateur a déjà achetés pour ce pari
    int userTicketsCountForCurrentBet = bet.participants
        .where((participant) => participant.startsWith('${currentUser.uid}_'))
        .length;

    // Déterminez le message du dialogue en fonction du nombre de tickets pour ce pari
    String dialogTitle;
    String dialogText;

    if (userTicketsCountForCurrentBet == 0) {
      dialogTitle = 'Acheter';
      dialogText = 'Voulez-vous tenter votre chance ?';
    } else {
      dialogTitle = 'Augmentez vos chances';
      dialogText =
          'Vous avez déjà acheté $userTicketsCountForCurrentBet ticket${userTicketsCountForCurrentBet > 1 ? 's' : ''} pour ce pari. Voulez-vous en acheter un autre pour augmenter vos chances ?';
    }

    QuickAlert.show(
      onCancelBtnTap: () {
        Navigator.pop(context);
      },
      context: context,
      type: QuickAlertType.confirm,
      title: dialogTitle,
      text: dialogText,
      textAlignment: TextAlign.center,
      confirmBtnText: "Oui, s'il vous plaît",
      cancelBtnTextStyle: const TextStyle(fontSize: 12.0, color: Colors.red),
      confirmBtnTextStyle: const TextStyle(fontSize: 12.0, color: Colors.white),
      cancelBtnText: 'Non, merci',
      confirmBtnColor: Coolors.purpleDark,
      onConfirmBtnTap: () async {
        if (currentUser.balance >= bet.participationSum) {
          double newBalance = currentUser.balance - bet.participationSum;
          String ticketId;

          // Générer un nouvel ID de ticket unique
          do {
            ticketId = _generateTicketId();
          } while (bet.participants
              .any((participant) => participant.endsWith('_$ticketId')));

          // Créer le format de l'ID de ticket pour l'utilisateur
          String userTicketId = '${currentUser.uid}_$ticketId';

          // Ajouter le ticket à la liste des participants du pari
          bet.participants.add(userTicketId);

          // Ajouter le ticket à la liste des tickets de l'utilisateur
          currentUser.addTicketId(ticketId);

          try {
            // Mettre à jour la liste des participants du pari dans la base de données
            await _betRepository.updateBetParticipants(
                bet.id, bet.participants);
            // Mettre à jour les tickets de l'utilisateur dans la base de données
            await _betRepository.updateUserTickets(
                currentUser.uid, currentUser.ticketIds!);

            setState(() {
              updateBalance(newBalance);
              Navigator.of(context).pop();
            });
            _showSuccessAlert(context);
            setState(() {});
          } catch (e) {
            print('Erreur lors de l\'ajout du participant au pari: $e');
            _showErrorAlert(context);
          }
        } else {
          _showInsufficientBalanceAlert(context);
        }
      },
    );
  }

  String _generateTicketId() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    final random = Random();
    String letterPart = String.fromCharCodes(
      Iterable.generate(
          3, (_) => letters.codeUnitAt(random.nextInt(letters.length))),
    );
    String digitPart = String.fromCharCodes(
      Iterable.generate(
          2, (_) => digits.codeUnitAt(random.nextInt(digits.length))),
    );
    return letterPart + digitPart;
  }

  void _showInsufficientBalanceAlert(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'Solde insuffisant',
      text:
          'Votre solde est insuffisant pour acheter ce ticket. Veuillez recharger votre compte.',
    );
  }

  void _showSuccessAlert(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: 'Félicitations ! Votre ticket a été acheté avec succès !',
    );
  }

  void _showErrorAlert(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Erreur',
      text: 'Le code secret est incorrect. Veuillez réessayer.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, WidgetRef ref, _) {
      String formatDuration(Duration duration) {
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
        return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
      }

      return StreamBuilder<List<BetModel>>(
        stream: widget.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/search.png',
                    width: 400,
                    height: 400,
                  ),
                  const Text(
                    'Aucun ticket pour le moment',
                    style: TextStyle(
                      fontFamily: 'Crimson Text',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          } else {
            final bets = snapshot.data!;
            // Tri de la liste des paris par date de création (du plus récent au plus ancien)
            bets.sort((a, b) => b.creationDate.compareTo(a.creationDate));
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bets.length,
              itemBuilder: (context, index) {
                final bet = bets[index];
                final remainingTime = bet.creationDate
                    .add(bet.duration)
                    .difference(DateTime.now());

                double convertedparticipationSum;
                double convertedpotentialGain;

                if (widget.currency == Currency.USD) {
                  convertedparticipationSum = bet.participationSum;
                  convertedpotentialGain = bet.potentialGain;
                } else {
                  convertedparticipationSum = ExchangeRate.convertFromUSD(
                      bet.participationSum, widget.currency);
                  convertedpotentialGain = ExchangeRate.convertFromUSD(
                      bet.potentialGain, widget.currency);
                }

                final formattedparticipationSum = formatPrice(
                    convertedparticipationSum, Localizations.localeOf(context));
                final formattedpotentialGain = formatPrice(
                    convertedpotentialGain, Localizations.localeOf(context));

                String currencySymbol;
                switch (widget.currency) {
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

                // Créez un GestureRecognizer pour détecter les appuis longs
                final longPressRecognizer = LongPressGestureRecognizer()
                  ..onLongPress = () {
                    // Vérifiez si l'utilisateur est un administrateur
                    if (currentUser != null &&
                        currentUser!.userType == 'admin') {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Supprimer la mise ?'),
                            content: const Text(
                                'Êtes-vous sûr de vouloir supprimer cette mise ?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(betRepositoryProvider)
                                      .deleteBet(bet.id);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Supprimer'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  };

                return GestureDetector(
                  onLongPress: longPressRecognizer.onLongPress,
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Coolors.greyDark,
                            child: Image.asset(
                              'assets/icon/avatar.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bet.description,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_money,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.currency == Currency.USD
                                          ? 'Coût du ticket : $currencySymbol $formattedparticipationSum'
                                          : 'Coût du ticket : $formattedparticipationSum $currencySymbol',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    const Icon(Icons.monetization_on,
                                        color: Coolors.purpleDark),
                                    const SizedBox(width: 4),
                                    Text(
                                      overflow: TextOverflow.ellipsis,
                                      widget.currency == Currency.USD
                                          ? 'Ticket gagnant : $currencySymbol $formattedpotentialGain'
                                          : 'Ticket gagnant : $formattedpotentialGain $currencySymbol',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (currentUser != null &&
                                  currentUser!.userType == 'admin')
                                Row(
                                  children: [
                                    const Icon(Icons.people),
                                    const SizedBox(width: 4),
                                    Text(
                                        'Nombre de participants : ${bet.participants.length}'),
                                  ],
                                ),
                              const SizedBox(height: 6),
                              if (remainingTime.inMinutes < 0 &&
                                  remainingTime.inMinutes < 30 &&
                                  bet.winners.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.emoji_events,
                                        color: Colors.amber.withOpacity(0.8)),
                                    const SizedBox(width: 4),
                                    Text(
                                        'Nombre de gagnants : ${bet.winners.length}'),
                                  ],
                                ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, child) {
                                    String timeLeft;
                                    IconData iconData;
                                    Color iconColor;
                                    Color textColor;

                                    if (remainingTime.inHours >= 1) {
                                      timeLeft =
                                          'Temps restants : ${formatDuration(remainingTime)}';
                                      iconData = Icons.access_time;
                                      iconColor = Coolors
                                          .greyDark; // Couleur de l'icône pour ce cas
                                    } else if (remainingTime.inMinutes >= 30 &&
                                        remainingTime.inHours < 1) {
                                      timeLeft =
                                          'Préparation des résultats ${formatDuration(remainingTime)}';
                                      iconData = Icons.pending;
                                      iconColor = Coolors.greyDark;
                                    } else if (remainingTime.inMinutes > 0 &&
                                        remainingTime.inMinutes < 30) {
                                      timeLeft =
                                          'Résultats disponibles dans ${formatDuration(remainingTime)}';
                                      iconData = Icons.check_circle;
                                      iconColor = Colors
                                          .green; // Couleur de l'icône pour ce cas
                                    } else {
                                      timeLeft = 'Vente clôturé';
                                      iconData = Icons.timer_outlined;
                                      iconColor = Colors
                                          .red; // Couleur de l'icône pour ce cas
                                    }

                                    textColor = remainingTime.inSeconds <= 0
                                        ? Colors.red
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color!;

                                    return Row(
                                      children: [
                                        Icon(
                                          iconData,
                                          color: iconColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeLeft,
                                          style: TextStyle(color: textColor),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: FutureBuilder<String?>(
                                future: _participationText(context, bet),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    return Transform.translate(
                                      offset: Offset(20,
                                          0), // Déplace le texte de 10 pixels vers la gauche
                                      child: Text(snapshot.data!),
                                    );
                                  } else {
                                    return SizedBox
                                        .shrink(); // Affiche rien si aucun message
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildParticipationButton(
                                  context, bet, currentUser),
                            ),
                            if (remainingTime.inMinutes > 0)
                              if (currentUser != null &&
                                  currentUser!.userType == 'admin' &&
                                  bet.winners.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _showChooseWinnersDialog(context, bet);
                                    },
                                    child: const Text(
                                      'Conclure la mise',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                            if (currentUser != null &&
                                currentUser!.userType == 'admin' &&
                                bet.winners.isNotEmpty)
                              bet.isGainSending
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 22.0, vertical: 8.0),
                                      child: Text(
                                        'Gain envoyé',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0, vertical: 8.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _sendGainsToWinners(
                                            context,
                                            bet,
                                            AuthRepository(
                                              auth: FirebaseAuth.instance,
                                              firestore:
                                                  FirebaseFirestore.instance,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          elevation: 2,
                                        ),
                                        child: const Text(
                                          'Envoyer les gains',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      );
    });
  }
}
