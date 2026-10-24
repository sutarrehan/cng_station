import 'package:geolocator/geolocator.dart';

/// Device location with explicit permission and service checks.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<bool> get isLocationServiceEnabled => Geolocator.isLocationServiceEnabled();

  Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw StateError('Location services are turned off. Enable GPS and try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('Location permission is permanently denied. Enable it in app settings.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
