# Wifi-Connect-App

This is a Flutter application that scans for nearby WiFi networks, displays them in a list, and allows connecting to a selected network.

## Source Code

[GitHub - (https://github.com/crypted420/wifi-connect-app)](https://github.com/crypted420/wifi-connect-app)

## IDE/Packages/Plugins Used

- **IDE:** Visual Studio Code / Android Studio
- **Framework:** Flutter
- **Packages:**
  - `wifi_scan`
  - `wifi_iot`
  - `permission_handler`
  - `geolocator`
  - `location`
  - `provider`
  - `flutter_riverpod`

## Platform Limitations

### iOS

iOS frequently returns a "permission permanently denied" status when requesting location permissions, even on first attempts. The app handles this by showing an explanatory error message and providing users with options to manually enable permissions through the device's app settings.

## Permissions and Database Logic

### Permissions

The app requests the following permissions:

- **Location:** Necessary for both Android and iOS to access WiFi information. The `permission_handler` package is used to request and check for location permissions.
- **WiFi:** The `wifi_scan` and `wifi_iot` packages handle the necessary permissions for scanning and connecting to WiFi networks.

### Database Logic

- A local `wifi_database.json` file is used to store known WiFi networks and their passwords.
- The app reads this file to check if a password is known for a given network.
- When connecting to a new network with a password, the app will (in a real-world scenario) securely store the new network credentials in this local database.

## Bonus Features & Notes

- The app is structured with a clear separation of concerns (models, providers, screens, services).
# wifi-connect-app
