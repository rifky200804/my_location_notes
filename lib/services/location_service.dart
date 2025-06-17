import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Digunakan untuk mendeteksi platform web
import 'dart:io' show Platform;

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

  static Future<void> openGoogleMapsNavigation(double lat, double lng) async {
    String googleMapsUrl;

    if (Platform.isAndroid) {
      // Coba skema https://www.google.com/maps
      googleMapsUrl = 'https://www.google.com/maps?q=$lat,$lng';
    } else if (Platform.isIOS) {
      googleMapsUrl = 'comgooglemaps://?q=$lat,$lng';
    } else {
      googleMapsUrl = 'https://maps.google.com/?q=$lat,$lng';
    }

    print('DEBUG: Mencoba meluncurkan URL (navigasi): $googleMapsUrl');

    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Tidak dapat membuka Google Maps untuk koordinat ($lat, $lng) di ${Platform.operatingSystem}. Pastikan aplikasi Google Maps terinstal atau URL valid. URL yang dicoba: $googleMapsUrl';
    }
  }

  // Fungsi static opsional untuk membuka Google Maps untuk arah dari lokasi saat ini ke target
  static Future<void> openGoogleMapsDirections(
    double destLat,
    double destLng,
  ) async {
    String googleMapsUrl;

    if (Platform.isAndroid) {
      // --- PERBAIKAN DI SINI: Menggunakan $destLat dan $destLng untuk interpolasi yang benar ---
      // 'google.navigation:q=' adalah skema khusus Google Maps untuk navigasi langsung di Android.
      // encodeUriComponent memastikan koordinat di-handle dengan benar (meskipun untuk angka, seringkali tidak wajib).
      final String encodedDestLat = Uri.encodeComponent(destLat.toString());
      final String encodedDestLng = Uri.encodeComponent(destLng.toString());
      googleMapsUrl = 'google.navigation:q=$encodedDestLat,$encodedDestLng';
    } else if (Platform.isIOS) {
      googleMapsUrl =
          'comgooglemaps://?daddr=$destLat,$destLng&directionsmode=driving';
    } else {
      googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving'; // Contoh universal
    }

    print(
      'DEBUG: Mencoba meluncurkan URL (platform-specific directions): $googleMapsUrl',
    );

    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print(
        'Tidak dapat membuka Google Maps untuk arah ke ($destLat, $destLng) di ${Platform.operatingSystem}. Pastikan aplikasi Google Maps terinstal atau URL valid. URL yang dicoba (ter-encode): $googleMapsUrl',
      );
      throw 'Tidak dapat membuka Google Maps untuk arah ke ($destLat, $destLng) di ${Platform.operatingSystem}. Pastikan aplikasi Google Maps terinstal atau URL valid. URL yang dicoba (ter-encode): $googleMapsUrl';
    }
  }
}
