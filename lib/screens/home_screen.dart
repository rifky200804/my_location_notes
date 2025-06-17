import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_location_notes/services/location_service.dart';
import 'package:my_location_notes/services/sensor_service.dart';
import 'package:my_location_notes/services/network_service.dart';
import 'package:my_location_notes/models/wisata.dart';
import 'package:my_location_notes/services/wisata_database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:my_location_notes/utils/app_router.dart';
import 'package:my_location_notes/widgets/custom_marker_icon.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MapController _mapController = MapController();
  LatLng _currentLatLng = const LatLng(-6.2088, 106.8456); // Default: Jakarta
  final List<Marker> _markers = [];
  Position? _currentPosition;

  double _accelerometerX = 0.0, _accelerometerY = 0.0, _accelerometerZ = 0.0;
  Color _backgroundColor = Colors.white;

  String _networkStatus = 'Mengecek...';

  String _deviceName = 'N/A';
  String _osVersion = 'N/A';

  final LocationService _locationService = LocationService();
  final WisataDatabaseService _databaseService = WisataDatabaseService();

  TextEditingController _namaWisataController = TextEditingController();
  final List<String> _kategoriOptions = [
    'Alam',
    'Kuliner',
    'Sejarah',
    'Budaya',
    'Edukasi',
    'Lainnya',
  ];
  String? _selectedKategori;

  final List<String> _kotaOptions = [
    'Jakarta',
    'Bandung',
    'Surabaya',
    'Yogyakarta',
    'Bali',
    'Depok',
  ];
  String? _selectedKota;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    SensorService.startAccelerometerListening();
    _listenToAccelerometer();
    NetworkService.startListening();
    _listenToNetworkChanges();
    _getDeviceInfo();
  }

  @override
  void dispose() {
    SensorService.stopAccelerometerListening();
    NetworkService.stopListening();
    _namaWisataController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    _currentPosition = await _locationService.getCurrentLocation();
    if (_currentPosition != null) {
      setState(() {
        _currentLatLng = LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        _markers.clear();
        _markers.add(
          Marker(
            point: _currentLatLng,
            width: 80,
            height: 80,
            child: const CustomMarkerIcon(
              iconData: Icons.my_location,
              iconColor: Colors.blue,
              iconSize: 45.0,
              tooltip: 'Posisi Anda',
            ),
          ),
        );
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _mapController.move(_currentLatLng, 15.0);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal mendapatkan lokasi. Pastikan GPS aktif dan izin diberikan.',
          ),
        ),
      );
    }
  }

  void _listenToAccelerometer() {
    SensorService.accelerometerStream.listen((event) {
      if (mounted) {
        setState(() {
          _accelerometerX = event.x;
          _accelerometerY = event.y;
          _accelerometerZ = event.z;

          if (_accelerometerX > 2.0) {
            _backgroundColor = Colors.lightBlue.shade100;
          } else if (_accelerometerX < -2.0) {
            _backgroundColor = Colors.lightGreen.shade100;
          } else {
            _backgroundColor = Colors.white;
          }
        });
      }
    });
  }

  void _listenToNetworkChanges() {
    NetworkService.connectivityStream.listen((
      List<ConnectivityResult> results,
    ) {
      if (mounted) {
        _updateNetworkStatusFromList(results);
      }
    });
    NetworkService.checkInitialConnectivity().then((results) {
      if (mounted) {
        _updateNetworkStatusFromList(results);
      }
    });
  }

  void _updateNetworkStatusFromList(List<ConnectivityResult> results) {
    setState(() {
      if (results.contains(ConnectivityResult.mobile)) {
        _networkStatus = 'Data Seluler';
      } else if (results.contains(ConnectivityResult.wifi)) {
        _networkStatus = 'Wi-Fi';
      } else if (results.contains(ConnectivityResult.none)) {
        _networkStatus = 'Tidak Ada Internet';
      } else {
        _networkStatus = 'Terhubung';
      }
    });
  }

  Future<void> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      WebBrowserInfo webBrowserInfo = await deviceInfo.webBrowserInfo;
      setState(() {
        _deviceName = webBrowserInfo.browserName.name;
        _osVersion = 'Web Browser';
      });
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _deviceName = androidInfo.model ?? 'Android Device';
        _osVersion =
            'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      });
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      setState(() {
        _deviceName = iosInfo.name ?? 'iOS Device';
        _osVersion = 'iOS ${iosInfo.systemVersion}';
      });
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      setState(() {
        _deviceName = windowsInfo.computerName;
        _osVersion =
            'Windows <span class="math-inline">\{windowsInfo\.majorVersion\}\.</span>{windowsInfo.minorVersion}';
      });
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macOsInfo = await deviceInfo.macOsInfo;
      setState(() {
        _deviceName = macOsInfo.model;
        _osVersion = 'macOS ${macOsInfo.osRelease}';
      });
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      setState(() {
        _deviceName = linuxInfo.name;
        _osVersion = 'Linux ${linuxInfo.versionId}';
      });
    }
  }

  Future<void> _addWisata() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat menambahkan wisata, lokasi belum tersedia.',
          ),
        ),
      );
      return;
    }

    _namaWisataController.clear();
    _selectedKota = null;
    _selectedKategori = null;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateInsideDialog) {
            return AlertDialog(
              title: const Text('Tambah Data Wisata'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _namaWisataController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Wisata',
                      ),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedKota,
                      decoration: const InputDecoration(
                        labelText: 'Kota',
                        border: OutlineInputBorder(),
                      ),
                      items: _kotaOptions.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateInsideDialog(() {
                          _selectedKota = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Pilih kota' : null,
                      hint: const Text('Pilih Kota'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedKategori,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: _kategoriOptions.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateInsideDialog(() {
                          _selectedKategori = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Pilih kategori' : null,
                      hint: const Text('Pilih Kategori'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_namaWisataController.text.trim().isEmpty ||
                        _selectedKota == null ||
                        _selectedKategori == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nama Wisata, Kota, dan Kategori tidak boleh kosong.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final newWisata = Wisata(
                        namaWisata: _namaWisataController.text.trim(),
                        kota: _selectedKota!,
                        kategori: _selectedKategori!,
                        latitude: _currentPosition!.latitude,
                        longitude: _currentPosition!.longitude,
                        timestamp: DateTime.now().toIso8601String(),
                        isFavorite: false,
                      );
                      print(
                        'DEBUG: Mengirim data wisata untuk disimpan: ${newWisata.toMap()}',
                      );
                      await _databaseService.insertWisata(newWisata);
                      print(
                        'DEBUG: Data wisata berhasil disimpan ke database!',
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data wisata berhasil disimpan!'),
                        ),
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      print('ERROR: Gagal menyimpan data wisata: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menyimpan data: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Lokasiku & Wisata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Lihat Semua Wisata',
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.wisataListRoute);
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Lihat Favorit',
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.favoritesListRoute);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentLatLng,
              zoom: 15.0,
              minZoom: 1.0,
              maxZoom: 18.0,
              onTap: (_, latlng) {
                print('Peta disentuh di: $latlng');
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.lokasiku_catatan_aman',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perangkat: $_deviceName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Versi OS: $_osVersion',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Text(
                      'Jaringan: $_networkStatus',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const Text('Data Accelerometer:'),
                    Text('X: ${_accelerometerX.toStringAsFixed(2)}'),
                    Text('Y: ${_accelerometerY.toStringAsFixed(2)}'),
                    Text('Z: ${_accelerometerZ.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              heroTag: "refreshLocationButton",
              onPressed: _fetchCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "addWisataButton",
        onPressed: _addWisata,
        tooltip: 'Tambah Data Wisata',
        child: const Icon(Icons.add),
      ),
    );
  }
}
