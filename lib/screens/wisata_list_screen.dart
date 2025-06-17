import 'package:flutter/material.dart';
import 'package:my_location_notes/models/wisata.dart';
import 'package:my_location_notes/services/wisata_database_service.dart';
import 'package:my_location_notes/services/location_service.dart'; 
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class WisataListScreen extends StatefulWidget {
  final String? kotaFilter;

  const WisataListScreen({super.key, this.kotaFilter});

  @override
  State<WisataListScreen> createState() => _WisataListScreenState();
}

class _WisataListScreenState extends State<WisataListScreen> {
  late Future<List<Wisata>> _wisataFuture;
  final WisataDatabaseService _databaseService = WisataDatabaseService();

  @override
  void initState() {
    super.initState();
    _loadWisata();
  }

  @override
  void didUpdateWidget(covariant WisataListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kotaFilter != widget.kotaFilter) {
      _loadWisata();
    }
  }

  void _loadWisata() {
    setState(() {
      _wisataFuture = _databaseService.getWisataList(kota: widget.kotaFilter);
    });
  }

  Future<void> _deleteWisata(int id) async {
    await _databaseService.deleteWisata(id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wisata berhasil dihapus.')));
    _loadWisata();
  }

  Future<void> _toggleFavorite(Wisata wisata) async {
    wisata.isFavorite = !wisata.isFavorite;
    await _databaseService.updateWisata(wisata);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${wisata.namaWisata} diatur sebagai favorit: ${wisata.isFavorite ? "Ya" : "Tidak"}.',
        ),
      ),
    );
    _loadWisata();
  }

  void _navigateToWisataLocation(Wisata wisata) async {
    // Buat URL Google Maps untuk koordinat pin (HTTPS universal)
    final String googleMapsUrl =
        'https://maps.google.com/?q=${wisata.latitude},${wisata.longitude}';

    try {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daftar Wisata ${widget.kotaFilter != null ? "di ${widget.kotaFilter}" : ""}',
        ),
      ),
      body: FutureBuilder<List<Wisata>>(
        future: _wisataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Belum ada tempat wisata${widget.kotaFilter != null ? " di ${widget.kotaFilter}" : ""}.',
              ),
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
                        // Tombol Favorite
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
                          onPressed: () => _navigateToWisataLocation(
                            wisata,
                          ), // Memanggil fungsi yang diperbarui
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
                          content: Text('Detail wisata: ${wisata.namaWisata}'),
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
