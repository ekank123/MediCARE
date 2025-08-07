import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamController<bool> _connectionStatusController;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _hasConnection = true;

  ConnectivityService() {
    _connectionStatusController = StreamController<bool>.broadcast();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Initialize connectivity
  Future<void> _initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      print('Connectivity check failed: $e');
      return;
    }
    return _updateConnectionStatus(result);
  }

  // Update connection status
  void _updateConnectionStatus(ConnectivityResult result) {
    bool hasConnection = result != ConnectivityResult.none;
    if (_hasConnection != hasConnection) {
      _hasConnection = hasConnection;
      _connectionStatusController.add(_hasConnection);
    }
  }

  // Get current connection status
  bool get hasConnection => _hasConnection;

  // Stream of connection status changes
  Stream<bool> get connectionStream => _connectionStatusController.stream;

  // Dispose
  void dispose() {
    _connectivitySubscription.cancel();
    _connectionStatusController.close();
  }

  // Check if currently connected
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _hasConnection = result != ConnectivityResult.none;
    return _hasConnection;
  }
}