import 'dart:async';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart' hide WifiNetwork;
import '../models/wifi_network.dart';
import '../services/wifi_service.dart';

final wifiServiceProvider = Provider((ref) => WifiService());

final wifiProvider =
    StateNotifierProvider<WifiNotifier, AsyncValue<List<WifiNetwork>>>((ref) {
      return WifiNotifier(ref.watch(wifiServiceProvider));
    });

class WifiNotifier extends StateNotifier<AsyncValue<List<WifiNetwork>>> {
  final WifiService _wifiService;
  StreamSubscription<List<WiFiAccessPoint>>? _scanSubscription;

  WifiNotifier(this._wifiService) : super(const AsyncValue.data([]));

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> scanAndConnect() async {
    state = const AsyncValue.loading();

    try {
      if (Platform.isAndroid) {
        await _handleAndroid();
      } else if (Platform.isIOS) {
        await _handleIOS();
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> _handleAndroid() async {
    final hasPermission = await _requestPermissions([
      Permission.location,
      Permission.nearbyWifiDevices,
    ]);

    if (!hasPermission) {
      state = AsyncValue.error('Permissions not granted', StackTrace.current);
      return;
    }

    final canScan = await WiFiScan.instance.canStartScan(askPermissions: true);
    if (canScan != CanStartScan.yes) {
      state = AsyncValue.error('Cannot start scan', StackTrace.current);
      return;
    }

    await WiFiScan.instance.startScan();
    _scanSubscription = WiFiScan.instance.onScannedResultsAvailable.listen((
      results,
    ) async {
      final dbNetworks = await _wifiService.loadWifiNetworks();
      final matchedNetworks = results
          .where((result) => dbNetworks.any((db) => db.ssid == result.ssid))
          .map((result) {
            final dbNetwork = dbNetworks.firstWhere(
              (db) => db.ssid == result.ssid,
            );
            return dbNetwork;
          })
          .toList();
      state = AsyncValue.data(matchedNetworks);
      _scanSubscription?.cancel();
    });
  }

  Future<void> _handleIOS() async {
    final hasPermission = await _requestPermissions([
      Permission.locationWhenInUse,
      Permission.locationAlways,
    ]);

    if (!hasPermission) {
      state = AsyncValue.error('Permissions not granted', StackTrace.current);
      return;
    }
    final location = Location();
    final currentLocation = await location.getLocation();
    final dbNetworks = await _wifiService.loadWifiNetworks();

    final nearbyNetworks = dbNetworks.where((network) {
      final distance = _calculateDistance(
        currentLocation.latitude!,
        currentLocation.longitude!,
        network.location['latitude']!,
        network.location['longitude']!,
      );
      return distance <= 50;
    }).toList();

    state = AsyncValue.data(nearbyNetworks);
  }

  Future<bool> _requestPermissions(List<Permission> permissions) async {
    final statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<List<Map<String, dynamic>>> getLocationBasedNetworks() async {
    final position = await Geolocator.getCurrentPosition();
    final dbNetworks = await _wifiService.loadWifiNetworks();

    return dbNetworks.map((wifi) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        wifi.location['latitude']!,
        wifi.location['longitude']!,
      );
      return {
        'ssid': wifi.ssid,
        'password': wifi.decryptedPassword,
        "password_encrypted": wifi.password_encrypted,
        'location': wifi.location,
        'isNearby': distance <= 50,
      };
    }).toList();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<void> connectToWifi(WifiNetwork network) async {
    if (Platform.isAndroid) {
      final result = await WiFiForIoTPlugin.connect(
        network.ssid,
        password: network.decryptedPassword,
        security: network.password_encrypted.isEmpty
            ? NetworkSecurity.NONE
            : NetworkSecurity.WPA,
      );
      if (!result) {
        state = AsyncValue.error(
          'Failed to connect to ${network.ssid}',
          StackTrace.current,
        );
      }
    }
  }
}
