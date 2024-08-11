import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:centi_cresento/main.dart';
import '../auth/controllers/auth_controller.dart';
import '../auth/repository/auth_repository.dart';
import '../features/bet/controllers/bet_controller.dart';
import '../features/bet/pages/bet_result_card.dart';
import '../models/bet_result.dart';
import '../models/user_model.dart';
import '../services/currency.dart';
import '../services/currency_determinate.dart';

class CommentPage extends ConsumerWidget {
  const CommentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final backgroundImage = themeMode == ThemeMode.dark
        ? 'assets/images/black.jpg'
        : 'assets/images/white.jpg';

    final authRepository = AuthRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );

    return Scaffold(
      body: Stack(
        children: [
          Image(
            height: double.infinity,
            width: double.infinity,
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final betResultsProvider =
                          ref.read(betControllerProvider).betResultsProvider;
                      final AsyncValue<List<BetResultModel>> betResultsState =
                          ref.watch(betResultsProvider);

                      return betResultsState.when(
                        data: (results) => _buildResultsList(
                            context, ref, results, authRepository),
                        loading: () => _buildShimmerLoader(),
                        error: (error, stackTrace) =>
                            Center(child: Text('Erreur: $error')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Container(
              height: 100,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, WidgetRef ref,
      List<BetResultModel> results, AuthRepository authRepository) {
    final List<Future<List<String>>> winnersNamesFutures = results
        .map((result) => authRepository.getUserNamesByIds(result.winners))
        .toList();

    return FutureBuilder<List<List<String>>>(
      future: Future.wait(winnersNamesFutures),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoader();
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else {
          final winnersNamesList = snapshot.data ?? [];

          return FutureBuilder<UserModel?>(
            future: ref.read(authControllerProvider).getCurrentUserInfo(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerLoader();
              } else if (userSnapshot.hasError) {
                return Center(child: Text('Erreur: ${userSnapshot.error}'));
              } else {
                final currentUser = userSnapshot.data;

                if (currentUser != null) {
                  Currency currency = CurrencyService.determineCurrency(
                      currentUser.latitude, currentUser.longitude);

                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return buildBetResultCard(
                        context,
                        results[index],
                        winnersNamesList[index],
                        currentUser,
                        currency,
                        ref,
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('Aucun résultat'));
                }
              }
            },
          );
        }
      },
    );
  }
}
