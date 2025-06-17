import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  // Menyimpan data sensitif (misalnya token atau status autentikasi)
  // Menggunakan Keychain di iOS dan KeyStore di Android, penyimpanan paling aman
  Future<void> saveSensitiveData(String key, String value) async {
    await _storage.write(key: key, value: value);
    print('DEBUG: Data sensitif "$key" disimpan dengan aman.');
  }

  // Mengambil data sensitif
  Future<String?> getSensitiveData(String key) async {
    final value = await _storage.read(key: key);
    print('DEBUG: Data sensitif "$key" diambil: $value');
    return value;
  }

  // Menghapus data sensitif
  Future<void> deleteSensitiveData(String key) async {
    await _storage.delete(key: key);
    print('DEBUG: Data sensitif "$key" dihapus.');
  }
}
