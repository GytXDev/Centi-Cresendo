// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:centi_cresento/home_section/card_page.dart';
import 'package:centi_cresento/home_section/comment_page.dart';
import 'package:centi_cresento/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../colors/coloors.dart';
import 'deposit.dart';
import 'new_bet.dart';
import 'withdrawal.dart';
import '../screen/widgets/bar_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final String? userType;
  bool isMounted = false;
  UserModel? currentUser;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

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

  Future<UserModel> getUserData(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    UserModel user = UserModel.fromMap(userDoc.data()!);
    print('User data retrieved: $user');
    return user;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<Widget>(
            future: _getPage(_currentIndex),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Coolors.blueDark,
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              return snapshot.data ?? Container();
            },
          ),
        ],
      ),
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Future<Widget> _getPage(int index) async {
    switch (index) {
      case 0:
        return const CardPage();
      case 1:
        if (currentUser?.userType == 'admin') {
          return const NewBet();
        } else {
          return const CommentPage();
        }
      case 2:
        if (currentUser?.userType == 'admin') {
          return const CommentPage();
        } else {
          return const Deposit();
        }
      case 3:
        if (currentUser?.userType == 'admin') {
          return const Deposit();
        } else {
          return const WithDrawal();
        }
      case 4:
        if (currentUser?.userType == 'admin') {
          return const WithDrawal();
        } else {
          return const SizedBox.shrink();
        }
      default:
        return Container();
    }
  }
}
