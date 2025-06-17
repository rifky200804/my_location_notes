import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkService {
  static StreamSubscription? _connectivitySubscription;
  static final StreamController<List<ConnectivityResult>>
  _connectivityController =
      StreamController<List<ConnectivityResult>>.broadcast();

  static Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivityController.stream;

  static void startListening() {
    if (_connectivitySubscription == null) {
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        (List<ConnectivityResult> result) {
          _connectivityController.add(result);
        },
        onError: (error) {
          print('Error di stream konektivitas: $error');
        },
        onDone: () {
          print('Stream konektivitas selesai.');
        },
      );
      print('DEBUG: Mulai mendengarkan perubahan konektivitas.');
    }
  }

  static void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    print('DEBUG: Berhenti mendengarkan perubahan konektivitas.');
  }

  static Future<List<ConnectivityResult>> checkInitialConnectivity() async {
    return await Connectivity().checkConnectivity();
  }
}
