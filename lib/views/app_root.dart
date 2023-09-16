import 'package:flutter/material.dart';

import '../resources/app_constants.dart';
import 'pages/home_page.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Barcode',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.cAppColor),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );();
  }
}
