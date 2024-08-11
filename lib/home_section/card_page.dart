// ignore_for_file: library_private_types_in_public_api

import 'package:centi_cresento/auth/repository/auth_repository.dart';
import 'package:centi_cresento/colors/extension/extension_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../auth/controllers/auth_controller.dart';
import '../colors/coloors.dart';
import '../features/bet/repository/bet_repository.dart';
import '../features/bet/widgets/bet_list_widget.dart';
import '../models/user_model.dart';
import '../screen/widgets/card.dart';
import '../services/currency_determinate.dart';
import 'settings_page.dart';

class CardPage extends StatefulWidget {
  const CardPage({Key? key}) : super(key: key);

  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage>
    with SingleTickerProviderStateMixin {
  late Future<int> userCountFuture;
  late double balanceFuture;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, WidgetRef ref, _) {
      final userModelAsyncValue = ref.watch(userProvider);
      userCountFuture = ref.read(authRepositoryProvider).getUserCount();

      return Scaffold(
        appBar: AppBar(
          backgroundColor: context.theme.lightText,
          title: userModelAsyncValue.when(
            data: (userModel) {
              if (userModel?.userType == 'admin') {
                return FutureBuilder<int>(
                  future: userCountFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Chargement...',
                        style: TextStyle(
                          color: context.theme.blackText,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text(
                        'Erreur',
                        style: TextStyle(
                          color: context.theme.blackText,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    } else {
                      final userCount = snapshot.data!;
                      return Text(
                        '$userCount Users',
                        style: TextStyle(
                          color: context.theme.blackText,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    }
                  },
                );
              } else {
                return null; // Retourner null si ce n'est pas un admin
              }
            },
            loading: () => null, // Retourner null pendant le chargement
            error: (error, stackTrace) =>
                null, // Retourner null en cas d'erreur
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.dehaze_sharp,
                color: Coolors.greyDark,
              ),
              onPressed: () {
                _showSettingsModal(context);
              },
            ),
          ],
        ),
        body: userModelAsyncValue.when(
          data: (userModel) {
            if (userModel == null) {
              return const Center(child: Text('No user found'));
            } else {
              final currentCurrency = CurrencyService.determineCurrency(
                userModel.latitude,
                userModel.longitude,
              );
              final userId = userModel.uid;
              return FutureBuilder<double?>(
                future: ref.read(authRepositoryProvider).getUserBalance(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: CardWidget(
                        balance: 0.0,
                        currency: currentCurrency,
                        accountNumber: userModel.accountNumber,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final balance = snapshot.data ?? 0.0;
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CardWidget(
                            balance: balance,
                            currency: currentCurrency,
                            accountNumber: userModel.accountNumber,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            margin: const EdgeInsets.only(left: 18),
                            child: const Text(
                              'Découvrez vos opportunités',
                              style: TextStyle(
                                  fontSize: 24, fontFamily: 'Crimson Text'),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          const SizedBox(height: 10),
                          BetListWidget(
                            stream: ref.watch(betRepositoryProvider).getBets(),
                            currency: currentCurrency,
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
        ),
      );
    });
  }
}

final userProvider = FutureProvider<UserModel?>((ref) {
  return ref.watch(authControllerProvider).getCurrentUserInfo();
});

void _showSettingsModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      );
    },
  );
}
