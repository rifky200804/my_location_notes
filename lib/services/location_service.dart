import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Digunakan untuk mendeteksi platform web

class LocationService {
  // Fungsi untuk mendapatkan lokasi geografis pengguna saat ini
  Future<Position?> getCurrentLocation() async {
    // 1. Memeriksa dan meminta izin lokasi secara kondisional (hanya di mobile, bukan web)
    if (!kIsWeb) {
      var permissionStatus = await Permission.locationWhenInUse.status;
      if (!permissionStatus.isGranted) {
        permissionStatus = await Permission.locationWhenInUse.request();
        if (!permissionStatus.isGranted) {
          print('Izin lokasi tidak diberikan di perangkat mobile.');
          return null;
        }
      }
    } else {
      print(
        'Deteksi platform adalah Web, melewati pengecekan izin permission_handler.',
      );
    }

    // 2. Memeriksa apakah layanan lokasi di perangkat/browser aktif
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Layanan lokasi dinonaktifkan di perangkat atau browser.');
      return null;
    }

    // 3. Mendapatkan lokasi saat ini dengan akurasi tinggi
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('Error mendapatkan lokasi: $e');
      if (kIsWeb) {
        print('Pastikan izin lokasi diberikan di browser Anda.');
      }
      return null;
    }
  }

  // Fungsi static untuk membuka aplikasi Google Maps dengan pin di koordinat tertentu
  static Future<void> openGoogleMapsNavigation(double lat, double lng) async {
   
    final Uri googleMapsUrl = Uri.parse('https://maps.google.com/?q=$lat,$lng');

    print(
      'DEBUG: Mencoba meluncurkan URL: $googleMapsUrl',
    ); 

    // Memeriksa apakah URL bisa diluncurkan oleh sistem
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      ); // Coba buka di aplikasi eksternal
    } else {
      // Pesan error yang lebih informatif jika gagal
      throw 'Tidak dapat membuka Google Maps untuk koordinat ($lat, $lng). Pastikan aplikasi Google Maps terinstal atau URL valid. URL yang dicoba: $googleMapsUrl';
    }
  }

  // Fungsi static opsional untuk membuka Google Maps untuk arah dari lokasi saat ini ke target
  static Future<void> openGoogleMapsDirections(
    double destLat,
    double destLng,
  ) async {
    // --- PERBAIKAN URL DI SINI (FORMAT STANDAR UNTUK ARAH) ---
    // Ini adalah format yang andal untuk meminta arah dari lokasi saat ini ke destinasi.
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving',
    );

    print(
      'DEBUG: Mencoba meluncurkan URL: $googleMapsUrl',
    ); // <--- Tambah print untuk debugging

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Tidak dapat membuka Google Maps untuk arah ke ($destLat, $destLng). Pastikan aplikasi Google Maps terinstal atau URL valid. URL yang dicoba: $googleMapsUrl';
    }
  }
}
