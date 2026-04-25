import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
// لێرەدا فایلە نوێیەکەمان ناساندووە بە بەرنامەکە
import 'screens/dashboard_screen.dart';

void main() async {
  // دڵنیابوونەوە لەوەی هەموو شتێک ئامادەیە پێش هەڵبوونی بەرنامەکە
  WidgetsFlutterBinding.ensureInitialized();

  // چالاککردنی فایەربەیس بەپێی ئەو سەکۆیەی بەرنامەکەی لەسەر کاردەکات (ئەندرۆید یان ئای ئۆ ئێس)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'بەڕێوەبردنی قەرزەکان',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 66, 123, 238),
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      // لێرەدا ڕاستەوخۆ دیزاینە نوێیەکە بانگ دەکەین
      home: const DashboardScreen(),
    );
  }
}
