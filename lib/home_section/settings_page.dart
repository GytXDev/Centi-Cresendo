// ignore_for_file: use_build_context_synchronously

import 'package:centi_cresento/colors/extension/extension_theme.dart';
import 'package:centi_cresento/home_section/welcome.dart';
import 'package:centi_cresento/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../colors/coloors.dart';
import '../lang/app_translation.dart';
import '../screen/widgets/custom_icon_button.dart';
import 'widgets/about_us.dart';
import 'widgets/settings_widget.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Fonction de déconnexion
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomePage(),
      ),
    );
  }

  late String currentLanguageCode = 'fr';

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

  void _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString = '';
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await prefs.setString('themeMode', modeString);
    ref.read(themeModeProvider.notifier).state = mode;
  }

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
                      'Change Language',
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
                    Navigator.of(context).pop();
                    // Mettre à jour l'interface utilisateur après le changement de langue
                    setState(() {});
                  },
                  activeColor: Coolors.purpleDark,
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
                    Navigator.of(context).pop();
                    // Mettre à jour l'interface utilisateur après le changement de langue
                    setState(() {});
                  },
                  activeColor: Coolors.purpleDark,
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
                AppLocalizations.of(context).translate('settingTitle'),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(height: 80),
              SettingItem(
                title: AppLocalizations.of(context).translate('languageText'),
                icon: Ionicons.language,
                bgColor: Coolors.purpleDark,
                iconColor: Colors.white,
                value: currentLanguageCode == 'fr'
                    ? AppLocalizations.of(context).translate('french')
                    : currentLanguageCode == 'en'
                        ? AppLocalizations.of(context).translate('english')
                        : '',
                onTap: () {
                  showBottomSheet(context);
                },
              ),
              const SizedBox(height: 20),
              SettingItem(
                title: AppLocalizations.of(context).translate('aboutUs'),
                icon: Icons.group,
                bgColor: Coolors.purpleDark,
                iconColor: Colors.white,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const AboutUs()));
                },
              ),
              const SizedBox(height: 20),
              SettingItem(
                title: AppLocalizations.of(context).translate('themeTitle'),
                icon: Icons.palette,
                bgColor: Coolors.purpleDark,
                iconColor: Colors.white,
                onTap: () async {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('chooseTheme'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () {
                                  _setThemeMode(ThemeMode.light);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('light'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _setThemeMode(ThemeMode.dark);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('dark'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _setThemeMode(ThemeMode.system);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('system'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              SettingItem(
                title: AppLocalizations.of(context).translate('logout'),
                icon: Ionicons.log_out_outline,
                bgColor: Coolors.purpleDark,
                iconColor: Colors.white,
                onTap: () {
                  QuickAlert.show(
                    onCancelBtnTap: () {
                      Navigator.pop(context);
                    },
                    context: context,
                    type: QuickAlertType.confirm,
                    title: "Confirmation",
                    text: 'Êtes-vous sûr de vouloir vous déconnecter ?',
                    textAlignment: TextAlign.center,
                    confirmBtnText: 'Oui',
                    cancelBtnText: 'Non',
                    onConfirmBtnTap: () {
                      _signOut();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
