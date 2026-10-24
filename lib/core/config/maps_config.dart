/// Google Maps configuration. Restrict the Android/iOS keys to the app IDs.
/// Supply keys through native manifests; never commit production keys.
class MapsConfig {
  MapsConfig._();
  static const String directionsBaseUrl = 'https://www.google.com/maps/dir/';
  static const String searchBaseUrl = 'https://www.google.com/maps/search/';
}
