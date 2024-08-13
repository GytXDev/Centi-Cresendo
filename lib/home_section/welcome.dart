import 'package:centi_cresento/auth/widgets/custom_button.dart';
import 'package:flutter/material.dart';

import '../colors/coloors.dart';
import '../lang/app_translation.dart';
import '../routes/route_page.dart';
import '../screen/widgets/languague.dart';

class WelcomePage extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  const WelcomePage({Key? key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _policyAccepted = false;
  bool _termsAccepted = false;

  void navigateToLoginPage(BuildContext context) {
    if (!_policyAccepted || !_termsAccepted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Conditions non acceptées'),
            content: const Text(
                'Vous devez d\'abord accepter la politique de confidentialité et les conditions d\'utilisation avant de pouvoir utiliser notre application.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  showPrivacyPolicyDialog(context);
                  showTermsOfServiceDialog(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Si les conditions sont acceptées, naviguer vers la page de connexion
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.login,
        (route) => false,
      );
    }
  }

  void showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                AppLocalizations.of(context).translate('privacyPolicy'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItem(
                      header: '1. Collecte et utilisation des informations',
                      content:
                          'Lorsque vous utilisez l’application Centi Crescendo, nous collectons des informations telles que votre adresse e-mail pour l’authentification via des fournisseurs tiers tels que Google ou Apple, et votre localisation pour personnaliser votre expérience. Ces informations sont utilisées pour améliorer nos services, assurer la sécurité de votre compte, et personnaliser votre expérience.',
                    ),
                    _buildItem(
                      header: '2. Protection des données',
                      content:
                          'La sécurité de vos données est une priorité pour nous. Toutes les informations que nous recueillons sont traitées de manière confidentielle et sécurisée. Nous mettons en œuvre des mesures de sécurité pour protéger vos données contre l’accès non autorisé, la divulgation ou l’utilisation abusive.',
                    ),
                    _buildItem(
                      header: '3. Notifications',
                      content:
                          'Centi Crescendo envoie des notifications aux utilisateurs pour les informer des résultats des tirages, des promotions spéciales et d’autres événements pertinents liés à l’application. Ces notifications sont envoyées via Firebase Cloud Messaging (FCM).',
                    ),
                    _buildItem(
                      header: '4. Autorisations de l’Application',
                      content:
                          'Certaines autorisations peuvent être nécessaires pour le bon fonctionnement de l’application, telles que l’accès à la localisation de votre appareil. Ces autorisations ne sont utilisées que pour les fonctionnalités de l’application à savoir l’ajustement de la devise et ne sont pas utilisées à d’autres fins.',
                    ),
                    _buildItem(
                      header: '5. Accès par des tiers',
                      content:
                          'Nous utilisons certains services tiers, tels que Firebase pour l’authentification et les notifications. Dans ce cas, seules les données agrégées et anonymisées sont partagées avec ces tiers.',
                    ),
                    _buildItem(
                      header:
                          '6. Utilisation de l\'API pour les paiements',
                      content:
                          'Centi Crescendo utilise une API de paiement sécurisé pour faciliter les paiements via Airtel Money et Moov Money. L\'utilisation de cette API garantit la confidentialité et la sécurité de vos informations financières lors des transactions.',
                    ),
                    _buildItem(
                      header: '7. Enfants',
                      content:
                          'L’application Centi Crescendo n’est pas destinée aux enfants de moins de 18 ans.',
                    ),
                    _buildItem(
                      header:
                          '8. Modifications de la Politique de Confidentialité',
                      content:
                          'Nous nous réservons le droit de modifier cette politique de confidentialité à tout moment. Toute modification sera publiée sur cette page et vous sera notifiée via l’application.',
                    ),
                    _buildItem(
                      header: 'Contact',
                      content:
                          'Si vous avez des questions ou des préoccupations concernant notre politique de confidentialité, veuillez nous contacter à l’adresse support@centicresento.com',
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _policyAccepted,
                          onChanged: (value) {
                            setState(() {
                              _policyAccepted = value!;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Accepter la politique de confidentialité',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                CustomElevatedButton(
                  onPressed: _policyAccepted
                      ? () {
                          Navigator.of(context).pop();
                        }
                      : () {},
                  text: 'OK',
                  textColor: Colors.white,
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showTermsOfServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                AppLocalizations.of(context).translate('termsOfServices'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'En utilisant l\'application Centi Crescendo, vous acceptez les conditions suivantes',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    _buildItem(
                      header: '1. Utilisation des services',
                      content:
                          'Vous reconnaissez et acceptez que l\'utilisation de Centi Crescendo est soumise à votre conformité avec ces conditions d\'utilisation, ainsi qu\'à toutes les lois et réglementations applicables.',
                    ),
                    _buildItem(
                      header: '2. Respect de la vie privée',
                      content:
                          'Vous comprenez et acceptez que Centi Crescendo collecte, traite et utilise vos informations personnelles conformément à sa politique de confidentialité.',
                    ),
                    _buildItem(
                      header: '3. Responsabilité de l\'utilisateur',
                      content:
                          'Vous êtes responsable de maintenir la confidentialité de vos informations de connexion et de toute activité qui se produit sous votre compte.',
                    ),
                    _buildItem(
                      header: '4. Utilisation appropriée',
                      content:
                          'Vous vous engagez à utiliser l\'application de manière légale, éthique et responsable, et à ne pas perturber ou compromettre le fonctionnement de l\'application.',
                    ),
                    _buildItem(
                      header: '5. Modifications des conditions',
                      content:
                          'Centi Crescendo se réserve le droit de modifier ces conditions d\'utilisation à tout moment, et il est de votre responsabilité de consulter régulièrement ces conditions pour toute mise à jour.',
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: (value) {
                            setState(() {
                              _termsAccepted = value!;
                            });
                          },
                        ),
                        const Text('Accepter les conditions d\'utilisation'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                CustomElevatedButton(
                  onPressed: _termsAccepted
                      ? () {
                          Navigator.of(context).pop();
                        }
                      : () {},
                  text: 'OK',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildItem({required String header, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            header,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Divider(color: Coolors.greyDark),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              AppLocalizations.of(context).translate('welcomeMessage'),
              style: const TextStyle(
                fontSize: 24,
                fontFamily: 'Permanent Marker',
              ),
            ),
            const SizedBox(height: 30.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                AppLocalizations.of(context).translate('readOur'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => showPrivacyPolicyDialog(context),
                  child: Text(
                    AppLocalizations.of(context).translate('privacyPolicy'),
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => showTermsOfServiceDialog(context),
                  child: Text(
                    AppLocalizations.of(context).translate('termsOfServices'),
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomElevatedButton(
              onPressed: () => navigateToLoginPage(context),
              text: AppLocalizations.of(context).translate('agreeAndContinue'),
              backgroundColor: Coolors.purpleDark,
              textColor: Colors.white,
            ),
            const SizedBox(height: 20),
            const LanguageButton(),
          ],
        ),
      ),
    );
  }
}
