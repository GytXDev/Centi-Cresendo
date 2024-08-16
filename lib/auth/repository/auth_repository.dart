// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:math';

import 'package:centi_cresento/features/bet/repository/bet_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:location/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart ';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../colors/helper_dialogue.dart';
import '../../colors/helpers/show_loading_dialog.dart';
import '../../lang/app_translation.dart';
//import '../../models/bet_result.dart';
import '../../models/bet_result.dart';
import '../../models/user_model.dart';
import '../../routes/route_page.dart';

final authRepositoryProvider = Provider(
  (ref) {
    return AuthRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );
  },
);

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository({
    required this.auth,
    required this.firestore,
  });

  Stream<UserModel> getUserPresenceStatus({required String uid}) {
    return firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((event) => UserModel.fromMap(event.data()!));
  }

  UserModel? adminUser;

  Future<bool> isFirstUser() async {
    QuerySnapshot usersSnapshot =
        await firestore.collection('users').limit(1).get();
    return usersSnapshot.docs.isEmpty;
  }

  Future<String?> getCurrentUserType() async {
    final userInfo =
        await firestore.collection('users').doc(auth.currentUser?.uid).get();
    return userInfo.data()?['userType'];
  }

  Future<UserModel?> getCurrentUserInfo() async {
    UserModel? user;
    final userInfo =
        await firestore.collection('users').doc(auth.currentUser?.uid).get();
    if (userInfo.data() == null) return user;
    user = UserModel.fromMap(userInfo.data()!);
    return user;
  }

  String generateAccountNumber() {
    String accountNumber = '';
    Random random = Random();
    for (int i = 0; i < 16; i++) {
      if (i != 0 && i % 4 == 0) {
        accountNumber += '-';
      }
      accountNumber +=
          random.nextInt(10).toString(); // Supprimez la conversion en double
    }
    return accountNumber;
  }

  // Fonction pour obtenir les coordonnées de latitude et de longitude
  Future<LocationData> getCoordinates() async {
    Location location = Location();
    return await location.getLocation();
  }

  Future<UserModel?> getUserByEmailAddress(String emailAddress) async {
    // Query the Firestore to get user by email address
    QuerySnapshot querySnapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: emailAddress)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return UserModel.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>);
    } else {
      return null;
    }
  }

  void saveUserInfoToFirestore({
    required String username,
    required ProviderRef ref,
    required BuildContext context,
    required bool mounted,
  }) async {
    try {
      PermissionStatus permissionStatus = await Location().requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: AppLocalizations.of(context).translate('error'),
          text:
              'Pour personnaliser l\'application selon votre devise, nous devons obtenir votre emplacement. ',
        );
        return;
      }

      showLoadingDialog(
        context: context,
        message: AppLocalizations.of(context).translate('savingUserInfo'),
      );

      String uid = auth.currentUser!.uid;
      LocationData locationData = await getCoordinates();
      double latitude = locationData.latitude!;
      double longitude = locationData.longitude!;

      bool isAdmin = await isFirstUser();
      UserModel? existingUser =
          await getUserByEmailAddress(auth.currentUser!.email!);

      if (existingUser == null) {
        // Aucun utilisateur existant, créer un nouvel utilisateur
        String accountNumber = generateAccountNumber();
        UserModel newUser = UserModel(
          username: username,
          uid: uid,
          email: auth.currentUser!.email!, // Utilisation de l'email
          userType: isAdmin ? 'admin' : 'user',
          latitude: latitude,
          longitude: longitude,
          accountNumber: accountNumber,
        );

        await firestore.collection('users').doc(uid).set(newUser.toMap());
        print('New user info saved to Firestore with UID: $uid');
      } else {
        // Utilisateur existant, mettre à jour les informations
        await firestore.collection('users').doc(uid).update({
          'username': username,
          'latitude': latitude,
          'longitude': longitude,
        });
      }

      Navigator.pop(context); // Ferme le dialogue de chargement
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false);
    } catch (e) {
      Navigator.pop(context);
      showAlertDialog(context: context, message: e.toString());
    }
  }

  User? getCurrentUser() {
    return auth.currentUser;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '127117263525-h7h854q9p3eico08b7s7n719q30bean9.apps.googleusercontent.com', // client ID pour le Web
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await auth.signInWithCredential(credential);
      }
    } catch (e) {
      print("Error signing in with Google: $e");
    }
    return null;
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await auth.signInWithCredential(credential);
    } catch (e) {
      print("Erreur lors de l'authentification avec Apple: $e");
      return null;
    }
  }

  // recharge compte
  Future<void> updateUserBalance({
    required UserModel user,
    required double amountToAdd,
    required String phoneNumber,
  }) async {
    try {
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(
          firestore.collection('users').doc(user.uid),
        );

        if (!snapshot.exists) {
          throw Exception('User does not exist!');
        }

        // Vérifier que snapshot.data() est de type Map<String, dynamic>
        if (snapshot.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData =
              snapshot.data() as Map<String, dynamic>;

          // Récupérer le solde actuel de l'utilisateur
          double currentBalance = (userData['balance'] ?? 0).toDouble();

          // Ajouter le montant à ajouter au solde actuel
          double updatedBalance = currentBalance + amountToAdd;

          // Mettre à jour le solde dans la base de données
          transaction.update(
            firestore.collection('users').doc(user.uid),
            {'balance': updatedBalance},
          );

          // Ajouter le numéro de transaction à la liste transactionNumbers s'il n'existe pas déjà
          List<String>? transactionNumbers = List<String>.from(
            userData['transactionNumbers'] ?? [],
          );
          if (!transactionNumbers.contains(phoneNumber)) {
            transactionNumbers.add(phoneNumber);
            transaction.update(
              firestore.collection('users').doc(user.uid),
              {'transactionNumbers': transactionNumbers},
            );
          }
        } else {
          throw Exception('Invalid user data format!');
        }
      });
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de la mise à jour des informations utilisateur: $e');
      rethrow;
    }
  }

  //Recharger le compte admin
  Future<void> updateBalance({
    required UserModel user,
    required double amountToAdd,
  }) async {
    try {
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(
          firestore.collection('users').doc(user.uid),
        );

        if (!snapshot.exists) {
          throw Exception('User does not exist!');
        }

        // Vérifier que snapshot.data() est de type Map<String, dynamic>
        if (snapshot.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData =
              snapshot.data() as Map<String, dynamic>;

          // Récupérer le solde actuel de l'utilisateur
          double currentBalance = (userData['balance'] ?? 0).toDouble();

          // Ajouter le montant à ajouter au solde actuel
          double updatedBalance = currentBalance + amountToAdd;

          // Mettre à jour le solde dans la base de données
          transaction.update(
            firestore.collection('users').doc(user.uid),
            {'balance': updatedBalance},
          );
        } else {
          throw Exception('Invalid user data format!');
        }
      });
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de la mise à jour des informations utilisateur: $e');
      rethrow;
    }
  }

  Future<void> updateAdminBalanceOther({required double amountToAdd}) async {
    try {
      await firestore.runTransaction((transaction) async {
        QuerySnapshot adminQuerySnapshot = await firestore
            .collection('users')
            .where('userType', isEqualTo: 'admin')
            .limit(1)
            .get();

        if (adminQuerySnapshot.docs.isNotEmpty) {
          DocumentSnapshot adminSnapshot = adminQuerySnapshot.docs.first;
          if (!adminSnapshot.exists) {
            throw Exception('Admin user does not exist!');
          }

          // Vérifier que snapshot.data() est de type Map<String, dynamic>
          if (adminSnapshot.data() is Map<String, dynamic>) {
            Map<String, dynamic> adminData =
                adminSnapshot.data() as Map<String, dynamic>;

            // Récupérer le solde actuel de l'administrateur
            double currentBalance = (adminData['balance'] ?? 0).toDouble();

            // Ajouter le montant à ajouter au solde actuel de l'administrateur
            double updatedBalance = currentBalance + amountToAdd;

            // Mettre à jour le solde dans la base de données
            transaction.update(
              firestore.collection('users').doc(adminSnapshot.id),
              {'balance': updatedBalance},
            );
          } else {
            throw Exception('Invalid admin data format!');
          }
        } else {
          throw Exception('Admin user not found!');
        }
      });
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de la mise à jour du solde administrateur: $e');
      rethrow;
    }
  }

  // Débiter compte
  Future<void> deductUserBalance({
    required UserModel user,
    required double amountInUSD,
  }) async {
    try {
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(
          firestore.collection('users').doc(user.uid),
        );

        if (!snapshot.exists) {
          throw Exception('User does not exist!');
        }

        // Vérifier que snapshot.data() est de type Map<String, dynamic>
        if (snapshot.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData =
              snapshot.data() as Map<String, dynamic>;

          // Récupérer le solde actuel de l'utilisateur
          double currentBalance = (userData['balance'] ?? 0).toDouble();

          // Ajouter le montant à ajouter au solde actuel
          double updatedBalance = currentBalance - amountInUSD;

          // Mettre à jour le solde dans la base de données
          transaction.update(
            firestore.collection('users').doc(user.uid),
            {'balance': updatedBalance},
          );
        } else {
          throw Exception('Invalid user data format!');
        }
      });
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de la mise à jour des informations utilisateur: $e');
      rethrow;
    }
  }

  Future<void> reducAdminBalance({required double amountToAdd}) async {
    try {
      await firestore.runTransaction((transaction) async {
        QuerySnapshot adminQuerySnapshot = await firestore
            .collection('users')
            .where('userType', isEqualTo: 'admin')
            .limit(1)
            .get();

        if (adminQuerySnapshot.docs.isNotEmpty) {
          DocumentSnapshot adminSnapshot = adminQuerySnapshot.docs.first;
          if (!adminSnapshot.exists) {
            throw Exception('Admin user does not exist!');
          }

          // Vérifier que snapshot.data() est de type Map<String, dynamic>
          if (adminSnapshot.data() is Map<String, dynamic>) {
            Map<String, dynamic> adminData =
                adminSnapshot.data() as Map<String, dynamic>;

            // Récupérer le solde actuel de l'administrateur
            double currentBalance = (adminData['balance'] ?? 0).toDouble();

            // Débiter le montant à ajouter au solde actuel de l'administrateur
            double updatedBalance = currentBalance - amountToAdd;

            // Mettre à jour le solde dans la base de données
            transaction.update(
              firestore.collection('users').doc(adminSnapshot.id),
              {'balance': updatedBalance},
            );
          } else {
            throw Exception('Invalid admin data format!');
          }
        } else {
          throw Exception('Admin user not found!');
        }
      });
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de la mise à jour du solde administrateur: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserByUid(String uid) async {
    // Query the Firestore to get user by phoneNumber
    QuerySnapshot querySnapshot =
        await firestore.collection('users').where('uid', isEqualTo: uid).get();

    if (querySnapshot.docs.isNotEmpty) {
      return UserModel.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>);
    } else {
      return null;
    }
  }

  // recharge compte
  Future<void> sendGainsToWinners({
    required UserModel user,
    required double amountToAdd,
    required String betId,
    required List<String> winners,
  }) async {
    try {
      final betRepository = BetRepository(
        firestore: FirebaseFirestore.instance,
      );

      await firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(
          firestore.collection('users').doc(user.uid),
        );

        if (!snapshot.exists) {
          throw Exception('User does not exist!');
        }

        // Vérifier que snapshot.data() est de type Map<String, dynamic>
        if (snapshot.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData =
              snapshot.data() as Map<String, dynamic>;

          // Récupérer le solde actuel de l'utilisateur
          double currentBalance = (userData['balance'] ?? 0).toDouble();

          // Ajouter le montant à ajouter au solde actuel
          double updatedBalance = currentBalance + amountToAdd;

          // Mettre à jour le solde dans la base de données
          transaction.update(
            firestore.collection('users').doc(user.uid),
            {'balance': updatedBalance},
          );
        } else {
          throw Exception('Invalid user data format!');
        }
      });
      // Dans la méthode sendGainsToWinners

      final betResultRef = firestore.collection('bet_results').doc(betId);
      final betResultSnapshot = await betResultRef.get();

      if (betResultSnapshot.exists) {
        // Le document pour ce pari existe déjà, mettez à jour les résultats des gains
        await betResultRef.update({
          'winners': FieldValue.arrayUnion(winners),
          'totalAmountWon': FieldValue.increment(amountToAdd),
          'dateSent': DateTime.now(),
        });
      } else {
        // Le document pour ce pari n'existe pas encore, créez-le
        final betResultModel = BetResultModel(
          betId: betId,
          winners: winners,
          totalAmountWon: amountToAdd,
          dateSent: DateTime.now(),
        );
        await betResultRef.set(betResultModel.toMap());
      }
      // Mettre à jour isGainSending à true dans le pari
      await betRepository.updateIsGainSending(betId, true);
    } catch (e) {
      // Gérer l'erreur
      print('Erreur lors de la mise à jour des informations utilisateur: $e');
      rethrow;
    }
  }

  Future<int> getUserCount() async {
    QuerySnapshot usersSnapshot = await firestore.collection('users').get();
    return usersSnapshot.docs.length;
  }

  Future<double> getUserBalance(String userId) async {
    try {
      final userInfo = await firestore.collection('users').doc(userId).get();
      if (userInfo.data() == null) {
        return 0.0; // Retourner une valeur par défaut si la balance n'est pas disponible
      }
      final balance = userInfo.data()?['balance'];
      if (balance is int) {
        // Si la valeur de la balance est de type int, la convertir en double
        return balance.toDouble();
      } else if (balance is double) {
        // Si la valeur de la balance est déjà de type double, la retourner telle quelle
        return balance;
      } else {
        // Si la valeur de la balance n'est ni int ni double, retourner 0.0 (ou une autre valeur par défaut)
        return 0.0;
      }
    } catch (e) {
      print('Error retrieving user balance: $e');
      return 0.0; // Retourner une valeur par défaut en cas d'erreur
    }
  }

  Future<List<String>> getUserNamesByIds(List<String> userIds) async {
    try {
      List<String> userNames = [];
      for (String userId in userIds) {
        final user = await firestore.collection('users').doc(userId).get();
        final userName = user['username'];
        userNames.add(userName);
      }
      return userNames;
    } catch (e) {
      print('Erreur lors de la récupération des noms d\'utilisateurs: $e');
      return [];
    }
  }
}
