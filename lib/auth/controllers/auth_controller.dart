// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../routes/route_page.dart';
import '../repository/auth_repository.dart';

final authControllerProvider = Provider(
  (ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    return AuthController(authRepository: authRepository, ref: ref);
  },
);

final userInfoAuthProvider = FutureProvider((ref) {
  final authController = ref.watch(authControllerProvider);
  return authController.getCurrentUserInfo();
});

class AuthController {
  final AuthRepository authRepository;

  final ProviderRef ref;

  AuthController({required this.authRepository, required this.ref});

  Stream<UserModel> getUserPresenceStatus({required String uid}) {
    return authRepository.getUserPresenceStatus(uid: uid);
  }

  Future<UserModel?> getCurrentUserInfo() async {
    UserModel? user = await authRepository.getCurrentUserInfo();
    return user;
  }

  void saveUserInfoToFirestore({
    required String username,
    required BuildContext context,
    required bool mounted,
  }) {
    authRepository.saveUserInfoToFirestore(
      username: username,
      ref: ref,
      context: context,
      mounted: mounted,
    );
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final UserCredential? userCredential =
          await authRepository.signInWithGoogle();
      if (userCredential != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.userInfo,
          (route) => false,
        );
      } else {
        print('erreur');
      }
    } catch (e) {
      print("Error signing in with Google: $e");
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    try {
      final UserCredential? userCredential =
          await authRepository.signInWithApple();
      if (userCredential != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.userInfo,
          (route) => false,
        );
      } else {
        print('erreur');
      }
    } catch (e) {
      print("Error signing in with Apple: $e");
    }
  }
}
