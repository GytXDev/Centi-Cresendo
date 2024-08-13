import 'package:centi_cresento/colors/extension/extension_theme.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../lang/app_translation.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ignore: deprecated_member_use
        backgroundColor: Theme.of(context).colorScheme.background,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Ionicons.chevron_back_outline,
              color: context.theme.blackText),
        ),
        leadingWidth: 80,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('aboutUs'),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Centi Crescendo version 4.0.1 © 2024',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Playfair Display',
                  color: context.theme.blackText,
                ),
              ),
              const SizedBox(height: 40),
              const Card(
                margin: EdgeInsets.symmetric(vertical: 16.0),
                elevation: 4.0,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Centi Crescendo est une application de vente de tickets de tombola en ligne qui offre une expérience ludique et accessible à tous. Avec des tickets à un prix vraiment insignifiant, chacun peut tenter sa chance pour remporter des gains exceptionnels.',
                        style: TextStyle(fontSize: 16.0),
                      ),
                      SizedBox(
                        height: 5.0,
                      ),
                      Text(
                        'Notre objectif est de rendre le divertissement de la tombola plus accessible que jamais, tout en offrant une chance de gagner de gros prix hebdomadairement. Nous croyons fermement que chacun devrait avoir la possibilité de participer à des jeux de hasard sans se ruiner.',
                        style: TextStyle(fontSize: 16.0),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
