// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

import 'package:test/common/config/app_theme.dart';
import 'package:test/controllers/main_controller.dart';
import 'package:test/screens/home.dart';
import 'package:test/screens/login.dart';
import 'package:test/screens/start.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(MainController());

    return GetMaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        SfGlobalLocalizations.delegate
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      locale: const Locale('vi'),
      debugShowCheckedModeBanner: false,
      enableLog: false,
      theme: ThemeApp.light(),
      initialRoute: "/",
      getPages: [
        GetPage(
          name: "/",
          page: () => const StartPage(),
        ),
        GetPage(
            name: "/login",
            page: () => const LoginPage(),
            transition: Transition.noTransition),
        GetPage(
            name: "/home",
            page: () => const Home(),
            transition: Transition.noTransition),
      ],
    );
  }
}
