import 'package:flutter/material.dart';

import '../components/scanner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Easy Scan"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showLicensePage(context: context, applicationName: "Easy Scan");
            },
          )
        ],
      ),
      body: const Scanner(),
    );
  }
}
