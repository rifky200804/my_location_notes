import 'package:flutter/material.dart';
import 'package:my_location_notes/screens/city_selection_screen.dart';
import 'package:my_location_notes/screens/home_screen.dart';
import 'package:my_location_notes/screens/wisata_list_screen.dart';
import 'package:my_location_notes/screens/favorites_list_screen.dart';

class AppRouter {
  // Definisi rute sebagai konstanta string
  static const String citySelectionRoute = '/'; // Rute awal aplikasi
  static const String homeRoute = '/home'; // Rute untuk halaman peta utama
  static const String wisataListRoute =
      '/wisata_list'; // Rute untuk daftar semua wisata
  static const String favoritesListRoute =
      '/favorites_list'; // Rute untuk daftar favorit

  // Fungsi untuk menghasilkan rute berdasarkan pengaturan rute
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case citySelectionRoute:
        return MaterialPageRoute(builder: (_) => const CitySelectionScreen());
      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case wisataListRoute:
        // Menerima argumen kotaFilter dari rute sebelumnya
        final args = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => WisataListScreen(kotaFilter: args),
        );
      case favoritesListRoute:
        return MaterialPageRoute(builder: (_) => const FavoritesListScreen());
      default:
        // Rute default jika nama rute tidak ditemukan
        return MaterialPageRoute(
          builder: (_) => const Text('Error: Route not found!'),
        );
    }
  }
}
