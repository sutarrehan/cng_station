import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/maps_config.dart';

/// Helpers for station map pins and safe Google Maps navigation URLs.
class MapsService {
  MapsService._();
  static final MapsService instance = MapsService._();

  Set<Marker> buildStationMarkers(
    Iterable<Map<String, dynamic>> stations, {
    required void Function(String stationId) onTap,
  }) {
    return stations.where((s) => s['latitude'] is num && s['longitude'] is num)
      .map((s) {
        final id = (s['id'] ?? '').toString();
        return Marker(
          markerId: MarkerId(id),
          position: LatLng((s['latitude'] as num).toDouble(), (s['longitude'] as num).toDouble()),
          infoWindow: InfoWindow(
            title: (s['name'] ?? 'CNG Station').toString(),
            snippet: s['pricePerKg'] == null ? null : '₹${s['pricePerKg']}/kg',
          ),
          onTap: () => onTap(id),
        );
      }).toSet();
  }

  Uri directionsUri({required double latitude, required double longitude}) =>
      Uri.parse(MapsConfig.directionsBaseUrl).replace(queryParameters: {
        'api': '1', 'destination': '$latitude,$longitude', 'travelmode': 'driving',
      });

  Uri stationSearchUri(String query) => Uri.parse(MapsConfig.searchBaseUrl).replace(
    queryParameters: {'api': '1', 'query': query},
  );
}
