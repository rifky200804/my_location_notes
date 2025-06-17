import 'package:flutter/material.dart';
import 'package:my_location_notes/models/wisata.dart';
import 'package:my_location_notes/services/wisata_database_service.dart';
import 'package:my_location_notes/services/location_service.dart';
import 'package:intl/intl.dart';
import 'package:my_location_notes/services/secure_storage_service.dart'; // Untuk autentikasi
import 'package:flutter/services.dart';

class FavoritesListScreen extends StatefulWidget {
  const FavoritesListScreen({super.key});

  @override
  State<FavoritesListScreen> createState() => _FavoritesListScreenState();
}

class _FavoritesListScreenState extends State<FavoritesListScreen> {
  late Future<List<Wisata>> _favoritesFuture;
  final WisataDatabaseService _databaseService = WisataDatabaseService();
  final SecureStorageService _secureStorageService = SecureStorageService();
  bool _isAuthenticated = false;
  final TextEditingController _passwordController = TextEditingController();

  // Password hardcoded untuk demo
  static const String _hardcodedPassword = '123'; // <--- Ubah password ini!
  static const String _authKey =
      'is_favorites_authenticated'; // Kunci untuk storage

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  // Cek status autentikasi saat awal layar dimuat
  Future<void> _checkAuthenticationStatus() async {
    String? storedAuth = await _secureStorageService.getSensitiveData(_authKey);
    if (storedAuth == 'true') {
      setState(() {
        _isAuthenticated = true;
      });
      _loadFavorites();
    } else {
      _showAuthenticationDialog(); // Tampilkan dialog jika belum terautentikasi
    }
  }

  // Menampilkan dialog autentikasi
  Future<void> _showAuthenticationDialog() async {
    _passwordController.clear(); // Bersihkan input sebelumnya
    await showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup tanpa input
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Akses Area Favorit'),
          content: TextField(
            controller: _passwordController,
            obscureText: true, // Untuk password
            decoration: const InputDecoration(
              labelText: 'Masukkan Password',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
                Navigator.of(
                  context,
                ).pop(); // Kembali ke layar sebelumnya jika dibatalkan
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_passwordController.text == _hardcodedPassword) {
                  await _secureStorageService.saveSensitiveData(
                    _authKey,
                    'true',
                  ); // Simpan status autentikasi
                  setState(() {
                    _isAuthenticated = true;
                  });
                  _loadFavorites();
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                } else {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Password salah!')),
                  );
                }
              },
              child: const Text('Masuk'),
            ),
          ],
        );
      },
    );
  }

  void _loadFavorites() {
    if (_isAuthenticated) {
      setState(() {
        _favoritesFuture = _databaseService.getWisataList(isFavorite: true);
      });
    }
  }

  Future<void> _deleteWisata(int id) async {
    await _databaseService.deleteWisata(id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wisata berhasil dihapus.')));
    _loadFavorites();
  }

  // Fungsi untuk toggle favorit (di layar favorit, ini akan menghapus dari daftar)
  Future<void> _toggleFavorite(Wisata wisata) async {
    wisata.isFavorite = !wisata.isFavorite; // Balik status favorit
    await _databaseService.updateWisata(wisata); // Update di database
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${wisata.namaWisata} diatur sebagai favorit: ${wisata.isFavorite ? "Ya" : "Tidak"}.',
        ),
      ),
    );
    _loadFavorites(); // Muat ulang daftar untuk refresh UI (akan menghilang jika tidak favorit lagi)
  }

  void _navigateToWisataLocation(Wisata wisata) async {
    // Buat URL Google Maps untuk koordinat pin (HTTPS universal)
    final String googleMapsUrl =
        'https://maps.google.com/?q=${wisata.latitude},${wisata.longitude}';

    try {
      // Salin URL ke clipboard
      await Clipboard.setData(ClipboardData(text: googleMapsUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan Google Maps berhasil disalin ke clipboard.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyalin tautan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading/autentikasi jika belum terautentikasi
    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daftar Favorit')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memeriksa autentikasi atau menunggu input password...'),
            ],
          ),
        ),
      );
    }

    // Tampilkan daftar favorit jika sudah terautentikasi
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Favorit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _secureStorageService.deleteSensitiveData(
                _authKey,
              ); // Logout
              setState(() {
                _isAuthenticated = false;
              });
              _showAuthenticationDialog(); // Minta login lagi
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<List<Wisata>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Belum ada tempat wisata favorit.'),
            );
          } else {
            final wisataList = snapshot.data!;
            return ListView.builder(
              itemCount: wisataList.length,
              itemBuilder: (context, index) {
                final wisata = wisataList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      wisata.namaWisata,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kota: ${wisata.kota}, Kategori: ${wisata.kategori}',
                        ),
                        Text(
                          'Lat: ${wisata.latitude.toStringAsFixed(4)}, Lng: ${wisata.longitude.toStringAsFixed(4)}',
                        ),
                        Text(
                          DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(DateTime.parse(wisata.timestamp)),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            wisata.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: wisata.isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(wisata),
                          tooltip: wisata.isFavorite
                              ? 'Hapus dari Favorit'
                              : 'Tambah ke Favorit',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.navigation,
                            color: Colors.blue,
                          ),
                          onPressed: () => _navigateToWisataLocation(wisata),
                          tooltip: 'Salin lokasi ke clipboard', // Tooltip baru
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteWisata(wisata.id!),
                          tooltip: 'Hapus wisata',
                        ),
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Detail favorit: ${wisata.namaWisata}'),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
