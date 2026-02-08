import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:safeplate/screens/home_screen.dart';
import 'screens/allergen_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/results_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  late Future<bool> _isFirstLaunch;

  @override
  void initState() {
    super.initState();
    _isFirstLaunch = _checkFirstLaunch();
  }

  Future<bool> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isSetupComplete = prefs.getBool('profile_setup_complete') ?? false;
    return !isSetupComplete;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePlate',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: _isFirstLaunch,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.data == true) {
            return AllergenScreen(
              onComplete: () {
                setState(() {
                  _isFirstLaunch = Future.value(false);
                });
              },
            );
          }

          return const HomeScreen();
        },
      ),
    );
  
  }

}