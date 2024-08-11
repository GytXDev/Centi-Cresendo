import 'package:flutter/material.dart';

import '../auth/pages/login_page.dart';
import '../auth/pages/user_info.dart';

import '../home_section/home_page.dart';
import '../home_section/welcome.dart';

class Routes {
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String verification = 'verification';
  static const String userInfo = 'user-info';
  static const String home = 'home';
  static const String contact = 'contact';
  static const String chat = 'chat';
  static const String profile = 'profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(
          builder: (context) => const WelcomePage(),
        );

      case login:
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
        );

      case userInfo:
        return MaterialPageRoute(
          builder: (context) => const UserInfoPage(),
        );

      case home:
        return MaterialPageRoute(
          builder: (context) => const HomePage(),
        );

      default:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('No Page Route Provided'),
            ),
          ),
        );
    }
  }
}
