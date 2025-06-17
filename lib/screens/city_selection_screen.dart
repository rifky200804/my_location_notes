import 'package:flutter/material.dart';
import 'package:my_location_notes/utils/app_router.dart';

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({super.key});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  String? _selectedCity;
  final List<String> _cities = [
    'Jakarta',
    'Bandung',
    'Surabaya',
    'Yogyakarta',
    'Bali',
    'Depok',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Kota Wisata')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Selamat Datang! Pilih kota untuk menjelajahi tempat wisata.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Pilih Kota',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
                value: _selectedCity,
                items: _cities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCity = newValue;
                  });
                },
                hint: const Text('Pilih Kota'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _selectedCity != null
                    ? () {
                        Navigator.pushNamed(
                          context,
                          AppRouter.wisataListRoute,
                          arguments: _selectedCity,
                        );
                      }
                    : null,
                child: const Text('Lihat Daftar Wisata'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.homeRoute);
                },
                child: const Text('Lihat Lokasi Saya (Peta)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.favoritesListRoute);
                },
                child: const Text('Lihat Daftar Favorit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
