
import 'package:background_locator_2/background_locator.dart';
import 'package:flutter/material.dart';
import 'package:gps_tracker/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundLocator.initialize();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Ilovaning asosiy vidjeti
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}
