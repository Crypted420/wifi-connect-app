import 'dart:convert';

class WifiNetwork {
  final String ssid;
  final String password_encrypted;
  final Map<String, double> location;

  WifiNetwork({
    required this.ssid,
    required this.password_encrypted,
    required this.location,
  });

  String get decryptedPassword {
    return utf8.decode(base64.decode(password_encrypted));
  }

  factory WifiNetwork.fromJson(Map<String, dynamic> json) {
    return WifiNetwork(
      ssid: json['ssid'],
      password_encrypted: json['password_encrypted'],
      location: Map<String, double>.from(json['location']),
    );
  }
}
