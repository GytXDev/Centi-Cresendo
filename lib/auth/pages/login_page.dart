// ignore_for_file: prefer_const_constructors

import 'package:centi_cresento/auth/controllers/auth_controller.dart';
import 'package:centi_cresento/colors/extension/extension_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../colors/coloors.dart';
//import '../../lang/app_translation.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  signInWithGoogle() {
    ref.read(authControllerProvider).signInWithGoogle(context);
  }

  signInWithApple() {
    // Appel à la méthode signInWithApple du AuthController
    ref.read(authControllerProvider).signInWithApple(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 80.0,
          ),
          const Text(
            'Bon retour parmi nous!',
            style: TextStyle(
              fontFamily: 'Permanent Marker',
              fontSize: 18.0,
              color: Coolors.greyDark,
            ),
          ),
          Image.asset(
            'assets/images/login.png',
            width: 270,
            height: 270,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 5,
            ),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'Continuer avec ',
                style: TextStyle(
                  color: context.theme.greyColor,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: signInWithGoogle,
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Google',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
