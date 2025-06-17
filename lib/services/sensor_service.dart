import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class SensorService {
  static StreamSubscription? _accelerometerSubscription;
  // StreamController untuk memancarkan event accelerometer ke listener
  static final StreamController<AccelerometerEvent> _accelerometerController =
      StreamController<AccelerometerEvent>.broadcast();

  // Getter untuk stream accelerometer
  static Stream<AccelerometerEvent> get accelerometerStream =>
      _accelerometerController.stream;

  // Memulai mendengarkan data accelerometer
  static void startAccelerometerListening() {
    if (_accelerometerSubscription == null) {
      // Pastikan hanya satu langganan aktif
      _accelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          _accelerometerController.add(event); // Tambahkan event ke stream
        },
        onError: (error) {
          print('Error di stream accelerometer: $error');
        },
        onDone: () {
          print('Stream accelerometer selesai.');
        },
      );
      print('DEBUG: Mulai mendengarkan accelerometer.');
    }
  }

  // Menghentikan mendengarkan data accelerometer
  static void stopAccelerometerListening() {
    _accelerometerSubscription?.cancel(); // Batalkan langganan
    _accelerometerSubscription = null; // Setel ulang
    print('DEBUG: Berhenti mendengarkan accelerometer.');
  }
}
