// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:centi_cresento/push_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/controllers/auth_controller.dart';
import 'colors/dark_theme.dart';
import 'colors/light_theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'lang/app_translation.dart';
import 'routes/route_page.dart';
import 'home_section/home_page.dart';
import 'home_section/welcome.dart';

Locale? initialLocale;

final navigatorKey = GlobalKey<NavigatorState>();

// function to lisen to background changes
Future _firebaseBackgroundMessage(RemoteMessage message) async {
  if (message.notification != null) {
    print("Some notification Received");
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // on background notification tapped
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.notification != null) {
      print("Background Notification Tapped");
      navigatorKey.currentState!.pushNamed("/ticket", arguments: message);
    }
  });

  PushNotifications.init();
  PushNotifications.localNotiInit();
  // Listen to background notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);

  // to handle foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    String payloadData = jsonEncode(message.data);
    print("Got a message in foreground");
    if (message.notification != null) {
      PushNotifications.showSimpleNotification(
          title: message.notification!.title!,
          body: message.notification!.body!,
          payload: payloadData);
    }
  });

  // for handling in terminated state
  final RemoteMessage? message =
      await FirebaseMessaging.instance.getInitialMessage();

  if (message != null) {
    print("Launched from terminated state");
    Future.delayed(const Duration(seconds: 1), () {
      navigatorKey.currentState!.pushNamed("/ticket", arguments: message);
    });
  }

  // Initialiser les données de localisation
  await initializeDateFormatting();

  // Récupérer la langue sauvegardée depuis SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  final savedLocale = sharedPreferences.getString('locale');

  String savedThemeMode =
      sharedPreferences.getString('themeMode') ?? 'ThemeMode.system';
  print("Saved theme mode: $savedThemeMode"); // Ajoutez cette ligne

  ThemeMode themeMode;
  switch (savedThemeMode) {
    case 'light':
      themeMode = ThemeMode.light;
      break;
    case 'dark':
      themeMode = ThemeMode.dark;
      break;
    default:
      themeMode = ThemeMode.system;
      break;
  }

  final container = ProviderContainer();
  container.read(themeModeProvider.notifier).state = themeMode;

  // Utiliser la langue sauvegardée ou la langue par défaut
  initialLocale =
      savedLocale != null ? Locale(savedLocale) : const Locale('fr');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'CentiCrescendo',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      debugShowCheckedModeBanner: false,
      locale: initialLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('fr', 'FR'),
      ],
      home: ref.watch(userInfoAuthProvider).when(
        data: (user) {
          FlutterNativeSplash.remove();
          if (user == null) return const WelcomePage();
          return const HomePage();
        },
        error: (Object error, StackTrace stackTrace) {
          print(error);
          return const Scaffold(
            body: Center(
              child: Text('Something wrong happened!'),
            ),
          );
        },
        loading: () {
          return const Scaffold(
            body: Center(
              child: Icon(
                Icons.whatshot_outlined,
                size: 30,
              ),
            ),
          );
        },
      ),
      routes: {'/ticket': (context) => const HomePage()},
      themeMode: themeMode,
      onGenerateRoute: Routes.onGenerateRoute,
    );
  }
}
