import 'package:centi_cresento/colors/extension/extension_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import '../../auth/repository/auth_repository.dart';
import '../../features/bet/pages/add_new_bet.dart';
import '../../models/user_model.dart';

class MyBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MyBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    final String? userType,
  });

  @override
  State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
}

Future<UserModel> getUserData(String uid) async {
  DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  UserModel user = UserModel.fromMap(userDoc.data()!);
  // ignore: avoid_print
  print('User data retrieved: $user');
  return user;
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  bool isFloatingBarOpen = false;
  final authRepository = AuthRepository(
      auth: FirebaseAuth.instance, firestore: FirebaseFirestore.instance);
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();

    getCurrentUser().then((user) {
      if (mounted) {
        setState(() {
          currentUser = user;
        });
      }
    });

    isMounted = true;
  }

  bool isMounted = false;

  Future<UserModel?> getCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return getUserData(user.uid);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("Error retrieving current user : $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          child: BottomNavigationBar(
            unselectedItemColor: Colors.white,
            selectedItemColor: context.theme.blackText,
            currentIndex: widget.currentIndex,
            onTap: (index) {
              if (index == 1 && currentUser?.userType == 'admin') {
                toggleFloatingBar();
              } else {
                widget.onTap(index);
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home,
                  color: context.theme.blackText,
                ),
                label: 'Accueil',
              ),
              if (currentUser != null && currentUser?.userType == 'admin')
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: context.theme.blackText,
                  ),
                  label: 'Jeu',
                ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons
                      .comment, // Nouvelle icône pour les commentaires des événements
                  color: context.theme.blackText,
                ),
                label:
                    'Notifications', // Nouvelle étiquette pour les commentaires des événements
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.account_balance_wallet,
                  color: context.theme.blackText,
                ),
                label: 'Recharge',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.money_off,
                  color: context.theme.blackText,
                ),
                label: 'Retrait',
              ),
            ],
          ),
        ),
        buildFloatingBar(),
      ],
    );
  }

  void toggleFloatingBar() {
    setState(() {
      isFloatingBarOpen = !isFloatingBarOpen;
    });
  }

  //widget pour les post
  Widget buildFloatingBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isFloatingBarOpen ? 200.0 : 0.0,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: context.theme.blackText,
                ),
                onPressed: () {
                  toggleFloatingBar();
                },
              ),
              const Flexible(
                child: Text(
                  'Créer une nouvelle mise',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20),
              IconButton(
                icon: Icon(
                  Icons.monetization_on,
                  color: context.theme.blackText,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddNewBet(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
