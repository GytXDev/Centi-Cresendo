import 'package:centi_cresento/colors/extension/extension_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../colors/coloors.dart';
import '../../colors/helper_dialogue.dart';
import '../../lang/app_translation.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_field.dart';

class UserInfoPage extends ConsumerStatefulWidget {
  const UserInfoPage({
    super.key,
  });

  @override
  ConsumerState<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends ConsumerState<UserInfoPage> {
  late TextEditingController usernameController;
  late final TextEditingController secretCodeController;

  saveUserDataToFirebase() {
    String username = usernameController.text;

    if (username.isEmpty) {
      return showAlertDialog(
        context: context,
        message:
            AppLocalizations.of(context).translate('pleaseProvideUsername'),
      );
    } else if (username.length < 3 || username.length > 20) {
      return showAlertDialog(
        context: context,
        message: AppLocalizations.of(context).translate('usernameLengthError'),
      );
    }

    ref.read(authControllerProvider).saveUserInfoToFirestore(
          username: username,
          context: context,
          mounted: mounted,
        );
  }

  @override
  void initState() {
    usernameController = TextEditingController();
    secretCodeController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    usernameController.dispose();
    secretCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 80,
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Veuillez fournir un nom utilisateur',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.theme.greyColor,
                    fontFamily: 'Permanent Marker',
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: CustomTextField(
                      controller: usernameController,
                      hinText: AppLocalizations.of(context)
                          .translate('typeYourNameHere'),
                      textAlign: TextAlign.center,
                      autoFocus: true,
                      hintText: '',
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: CustomElevatedButton(
        onPressed: saveUserDataToFirebase,
        text: AppLocalizations.of(context).translate('next'),
        buttonWidth: 120,
        backgroundColor: Coolors.blueDark,
      ),
    );
  }
}
