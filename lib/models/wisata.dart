class Wisata {
  int? id; // ID unik untuk setiap entri, auto-increment di DB
  String namaWisata;
  String kota;
  String kategori;
  double latitude;
  double longitude;
  String timestamp; // Waktu pembuatan atau update
  bool isFavorite; // Status favorit (true/false)

  Wisata({
    this.id,
    required this.namaWisata,
    required this.kota,
    required this.kategori,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.isFavorite = false, // Defaultnya tidak favorit
  });

  // Metode factory untuk membuat objek Wisata dari Map (misalnya dari hasil query database)
  factory Wisata.fromMap(Map<String, dynamic> map) {
    return Wisata(
      id: map['id'],
      namaWisata: map['namaWisata'],
      kota: map['kota'],
      kategori: map['kategori'],
      // Konversi ke double secara aman, karena nilai dari DB bisa int atau double
      latitude: map['latitude'] is int
          ? (map['latitude'] as int).toDouble()
          : map['latitude'],
      longitude: map['longitude'] is int
          ? (map['longitude'] as int).toDouble()
          : map['longitude'],
      timestamp: map['timestamp'],
      isFavorite:
          map['isFavorite'] ==
          1, // SQLite menyimpan boolean sebagai 0 (false) atau 1 (true)
    );
  }

  // Metode untuk mengkonversi objek Wisata menjadi Map (untuk disimpan ke database)
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Jika id null, DB akan auto-generate
      'namaWisata': namaWisata,
      'kota': kota,
      'kategori': kategori,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'isFavorite': isFavorite ? 1 : 0, // Simpan boolean sebagai 0 atau 1
    };
  }
}
