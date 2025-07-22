
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/wifi_network.dart';

class WifiService {
  Future<List<WifiNetwork>> loadWifiNetworks() async {
    final String response = await rootBundle.loadString('assets/wifi_database.json');
    final List<dynamic> data = json.decode(response);
    return data.map((json) => WifiNetwork.fromJson(json)).toList();
  }
}
