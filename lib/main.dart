import 'package:flutter/material.dart';
import 'package:my_location_notes/screens/city_selection_screen.dart';
import 'package:my_location_notes/utils/app_router.dart';

// Import untuk inisialisasi Sqflite dan deteksi platform
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:io' show Platform; // <--- PASTIKAN IMPORT INI ADA

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INISIALISASI DATABASE FACTORY KONDISIONAL ---
  if (kIsWeb) {
    // Untuk platform web
    databaseFactory = databaseFactoryFfiWeb;
    print('DEBUG: Sqflite initialized for WEB.');
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // <--- PASTIKAN BLOK INI ADA DAN KONDISINYA BENAR
    // Untuk platform desktop (Windows, macOS, Linux)
    sqfliteFfiInit(); // Inisialisasi FFI untuk desktop
    databaseFactory = databaseFactoryFfi; // Atur factory database untuk desktop
    print('DEBUG: Sqflite initialized for DESKTOP.');
  }
  // TIDAK ADA 'else' DI SINI UNTUK ANDROID/IOS.
  // Sqflite akan menggunakan native backend-nya secara otomatis di Android/iOS.
  print(
    'DEBUG: Sqflite will use native backend for Android/iOS (no explicit FFI setup needed).',
  );
  // --- AKHIR INISIALISASI ---

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lokasiku & Wisata',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.citySelectionRoute,
    );
  }
}
