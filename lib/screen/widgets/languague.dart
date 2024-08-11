import 'package:centi_cresento/colors/extension/extension_theme.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../colors/coloors.dart';
import '../../home_section/welcome.dart';
import '../../lang/app_translation.dart';
import 'custom_icon_button.dart';

class LanguageButton extends StatefulWidget {
  const LanguageButton({super.key});

  @override
  State<LanguageButton> createState() => _LanguageButtonState();
}

class _LanguageButtonState extends State<LanguageButton> {
  @override
  void initState() {
    super.initState();

    // Récupérer la langue actuelle depuis SharedPreferences
    SharedPreferences.getInstance().then((sharedPreferences) {
      setState(() {
        currentLanguageCode = sharedPreferences.getString('locale') ?? 'fr';

        // Mettre à jour les booléens en fonction de la langue actuelle
        isFrench = currentLanguageCode == 'fr';
        isEnglish = currentLanguageCode == 'en';
      });
    });
  }

  bool isFrench = true;
  bool isEnglish = false;

  late String currentLanguageCode = 'fr';

  void showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 30,
                  decoration: BoxDecoration(
                    color: context.theme.greyColor!.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                    ),
                    CustomIconButton(
                      onTap: () => Navigator.of(context).pop(),
                      icon: Icons.close_outlined,
                      iconColor: context.theme.blackText,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      'Lumina Language',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                RadioListTile(
                  value: 'french',
                  groupValue: isFrench ? 'french' : null,
                  onChanged: (value) {
                    setState(() {
                      isFrench = true;
                      isEnglish = false;
                    });
                    AppLocalizations.of(context)
                        .changeLocale(const Locale('fr', 'FR'));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomePage(),
                      ),
                    );
                    setState(() {});
                  },
                  activeColor: Coolors.blueDark,
                  title: Text(AppLocalizations.of(context).translate('french')),
                  subtitle: Text(
                    AppLocalizations.of(context).translate('frenchSubtitle'),
                    style: TextStyle(
                      color: context.theme.greyColor,
                    ),
                  ),
                ),
                RadioListTile(
                  value: 'english',
                  groupValue: isEnglish ? 'english' : null,
                  onChanged: (value) {
                    setState(() {
                      isFrench = false;
                      isEnglish = true;
                    });
                    AppLocalizations.of(context)
                        .changeLocale(const Locale('en', 'US'));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomePage(),
                      ),
                    );
                    setState(() {});
                  },
                  activeColor: Coolors.blueDark,
                  title:
                      Text(AppLocalizations.of(context).translate('english')),
                  subtitle: Text(
                    AppLocalizations.of(context).translate('englishSubtitle'),
                    style: TextStyle(
                      color: context.theme.greyColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.theme.langBtnBgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          showBottomSheet(context);
        },
        borderRadius: BorderRadius.circular(20),
        splashFactory: NoSplash.splashFactory,
        highlightColor: context.theme.langBtnHighLightColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language,
                color: Coolors.blueDark,
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                isFrench
                    ? AppLocalizations.of(context).translate('french')
                    : (isEnglish
                        ? AppLocalizations.of(context).translate('english')
                        : ''),
                style: const TextStyle(
                  color: Coolors.greyDark,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Coolors.blueDark,
              )
            ],
          ),
        ),
      ),
    );
  }
}
