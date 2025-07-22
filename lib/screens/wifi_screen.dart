import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/wifi_network.dart';
import '../providers/wifi_provider.dart';

class WifiScreen extends ConsumerStatefulWidget {
  const WifiScreen({super.key});

  @override
  ConsumerState<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends ConsumerState<WifiScreen> {
  bool _showLocationBasedNetworks = false;
  List<Map<String, dynamic>> _locationBasedNetworks = [];

  Future<void> _loadLocationBasedNetworks() async {
    final locationPermission = await Permission.location.status;
    if (locationPermission.isGranted) {
      final networks = await ref
          .read(wifiProvider.notifier)
          .getLocationBasedNetworks();
      setState(() {
        _locationBasedNetworks = networks;
      });
    } else {
      final alwaysStatus = await Permission.locationAlways.status;
      final whenInUseStatus = await Permission.locationWhenInUse.status;
      print(alwaysStatus);
      if (alwaysStatus.isDenied || whenInUseStatus.isDenied) {
        // Show dialog explaining need for permissions
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'This app needs location permissions to scan for nearby WiFi networks. '
              'Please enable location permissions in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                  setState(() {
                    _showLocationBasedNetworks = false;
                  });
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wifiState = ref.watch(wifiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Connect'),
        leading: _showLocationBasedNetworks
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showLocationBasedNetworks = false;
                  });
                },
              )
            : null,
      ),
      body: Center(
        child: _showLocationBasedNetworks
            ? _locationBasedNetworks.isEmpty
                  ? const CircularProgressIndicator()
                  : ListView.builder(
                      itemCount: _locationBasedNetworks.length,
                      itemBuilder: (context, index) {
                        final network = _locationBasedNetworks[index];
                        return ListTile(
                          title: Text(network['ssid'] ?? 'Unknown SSID'),
                          subtitle: Text(
                            'Nearby: ${network['isNearby'] ? "Yes" : 'No'}',
                          ),

                          onTap: () => _showPasswordDialog(
                            context,
                            WifiNetwork.fromJson(network),
                          ),
                        );
                      },
                    )
            : wifiState.when(
                data: (networks) {
                  if (networks.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            ref.read(wifiProvider.notifier).scanAndConnect();
                          },
                          child: const Text('Scan & Connect to WiFi'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showLocationBasedNetworks = true;
                              _loadLocationBasedNetworks();
                            });
                          },
                          child: const Text("Show location based networks"),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    itemCount: networks.length,
                    itemBuilder: (context, index) {
                      final network = networks[index];
                      return ListTile(
                        title: Text(network.ssid),
                        onTap: () {
                          if (Platform.isAndroid) {
                            ref
                                .read(wifiProvider.notifier)
                                .connectToWifi(network);
                          } else {
                            _showPasswordDialog(context, network);
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error.toString()),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(wifiProvider.notifier).scanAndConnect();
                        },
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          await openAppSettings();
                        },
                        child: const Text("Open app settings"),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showLocationBasedNetworks = true;
                            _loadLocationBasedNetworks();
                          });
                        },
                        child: const Text("Show location based networks"),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, WifiNetwork network) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(network.ssid),
          content: Text('Password: ${network.decryptedPassword}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () => {
                ref.read(wifiProvider.notifier).connectToWifi(network),
              },
              child: Text("Connect"),
            ),
          ],
        );
      },
    );
  }
}
