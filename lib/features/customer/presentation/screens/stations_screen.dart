import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/location_service.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  bool _mapMode = true;
  bool _locating = false;
  Position? _position;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (!mounted) return;
      setState(() => _position = position);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          13,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location unavailable: $error')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  double _distance(Map<String, dynamic> data) {
    final lat = _number(data['latitude'] ?? data['lat']);
    final lng = _number(data['longitude'] ?? data['lng']);
    if (_position == null || lat == null || lng == null) {
      return double.infinity;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return double.infinity;
    }
    return Geolocator.distanceBetween(
          _position!.latitude,
          _position!.longitude,
          lat,
          lng,
        ) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('stations')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Stations load झाले नाहीत. Internet connection आणि Firestore rules तपासा.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final query = _search.trim().toLowerCase();
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          final name = (data['name'] ?? '').toString().toLowerCase();
          final address = (data['address'] ?? '').toString().toLowerCase();
          return name.contains(query) || address.contains(query);
        }).toList()
          ..sort((a, b) => _distance(a.data()).compareTo(_distance(b.data())));

        final markers = <Marker>{};
        for (final doc in docs) {
          final data = doc.data();
          final lat = _number(data['latitude'] ?? data['lat']);
          final lng = _number(data['longitude'] ?? data['lng']);
          if (lat == null ||
              lng == null ||
              lat < -90 ||
              lat > 90 ||
              lng < -180 ||
              lng > 180) {
            continue;
          }
          markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: data['name']?.toString() ?? 'CNG Station',
                snippet: '₹${data['pricePerKg'] ?? '—'}/kg',
              ),
              onTap: () => _showDetails(doc.id, data),
            ),
          );
        }

        final center = _position != null
            ? LatLng(_position!.latitude, _position!.longitude)
            : (markers.isNotEmpty
                ? markers.first.position
                : const LatLng(18.5204, 73.8567));
        final showMap = _mapMode && !kIsWeb;

        return Container(
          color: AppColors.background,
          child: Column(
            children: [
              _topControls(docs.length),
              if (kIsWeb && _mapMode) _webNotice(),
              Expanded(
                child: docs.isEmpty
                    ? const _EmptyStations()
                    : showMap
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: GoogleMap(
                              initialCameraPosition:
                                  CameraPosition(target: center, zoom: 11),
                              markers: markers,
                              myLocationEnabled: _position != null,
                              myLocationButtonEnabled: true,
                              onMapCreated: (controller) =>
                                  _mapController = controller,
                            ),
                          )
                        : Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 20),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final doc = docs[index];
                                  return _stationCard(doc.id, doc.data());
                                },
                              ),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _topControls(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _search = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search station or address',
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.green, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Use my location',
                child: Material(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _locating ? null : _locate,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Center(
                        child: _locating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location,
                                color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count active stations',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.map_outlined, size: 18),
                    label: Text('Map'),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.list_alt, size: 18),
                    label: Text('List'),
                  ),
                ],
                selected: {_mapMode},
                onSelectionChanged: (values) =>
                    setState(() => _mapMode = values.first),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _webNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.map_outlined, color: AppColors.green, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Free web mode: map preview is paused to avoid API billing. Browse stations below and open directions in Google Maps.',
              style: TextStyle(color: AppColors.text, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stationCard(String id, Map<String, dynamic> data) {
    final distance = _distance(data);
    final distanceLabel = distance.isFinite
        ? '${distance.toStringAsFixed(1)} km away'
        : 'Distance unavailable';
    final availability =
        (data['availability'] ?? 'Availability unknown').toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F075B43),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDetails(id, data),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_gas_station,
                        color: AppColors.green,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name']?.toString() ?? 'CNG Station',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            data['address']?.toString() ??
                                'Address unavailable',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data['pricePerKg'] == null
                          ? 'Price N/A'
                          : '₹${data['pricePerKg']}/kg',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _smallBadge(Icons.near_me_outlined, distanceLabel),
                    _smallBadge(Icons.people_outline,
                        'Queue ${data['queueCount'] ?? '—'}'),
                    _smallBadge(Icons.circle, availability),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _directions(data),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _book(id),
                        icon: const Icon(Icons.confirmation_number_outlined,
                            size: 18),
                        label: const Text('Book token'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(String id, Map<String, dynamic> data) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.local_gas_station,
                          color: AppColors.green, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name']?.toString() ?? 'CNG Station',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['address']?.toString() ??
                                'Address not provided',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _detailChip(Icons.currency_rupee,
                        '${data['pricePerKg'] ?? '—'} / kg'),
                    _detailChip(Icons.people_alt_outlined,
                        'Queue ${data['queueCount'] ?? '—'}'),
                    _detailChip(Icons.access_time,
                        'Wait ${data['estimatedWaitMinutes'] ?? '—'} min'),
                    _detailChip(
                        Icons.circle, '${data['availability'] ?? 'Unknown'}'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _directions(data),
                    icon: const Icon(Icons.directions),
                    label: const Text('Get directions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _book(id);
                    },
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: const Text('Book queue token'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String label) => Chip(
        avatar: Icon(icon, size: 16, color: AppColors.green),
        label: Text(label),
        backgroundColor: AppColors.mint,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      );

  Future<void> _directions(Map<String, dynamic> data) async {
    final lat = _number(data['latitude'] ?? data['lat']);
    final lng = _number(data['longitude'] ?? data['lng']);
    final Uri uri;
    if (lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180) {
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    } else {
      final query = Uri.encodeComponent(
        '${data['name'] ?? 'CNG station'} ${data['address'] ?? ''}',
      );
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Directions error: $error')),
      );
    }
  }

  Future<void> _book(String stationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token book करण्यासाठी login करा.')),
      );
      return;
    }

    try {
      final vehicles = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('customerId', isEqualTo: uid)
          .get();
      final profile =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final primary = profile.data()?['vehicle'];
      String? selected =
          vehicles.docs.isNotEmpty ? vehicles.docs.first.id : null;
      if (vehicles.docs.isEmpty &&
          primary is Map &&
          (primary['number']?.toString().isNotEmpty ?? false)) {
        selected = 'profile_vehicle';
      }
      if (!mounted) return;
      if (selected == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('आधी Vehicle tab मध्ये vehicle save करा.')),
        );
        return;
      }

      final chosen = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          String? value = selected;
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Choose vehicle'),
              content: DropdownButtonFormField<String>(
                initialValue: value,
                isExpanded: true,
                items: [
                  ...vehicles.docs.map((doc) {
                    final vehicle = doc.data();
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(
                          '${vehicle['number'] ?? 'Vehicle'} ${vehicle['model'] ?? ''}'),
                    );
                  }),
                  if (primary is Map &&
                      (primary['number']?.toString().isNotEmpty ?? false))
                    DropdownMenuItem<String>(
                      value: 'profile_vehicle',
                      child: Text(
                          '${primary['number']} ${primary['model'] ?? ''}'),
                    ),
                ],
                onChanged: (newValue) => setDialogState(() => value = newValue),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: value == null
                      ? null
                      : () => Navigator.pop(dialogContext, value),
                  child: const Text('Book token'),
                ),
              ],
            ),
          );
        },
      );
      if (chosen == null || !mounted) return;

      final token = await FirestoreService().createToken(
        stationId: stationId,
        vehicleId: chosen == 'profile_vehicle' ? null : chosen,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Token booked'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.confirmation_number,
                  size: 48, color: AppColors.green),
              const SizedBox(height: 8),
              const Text('Your booking reference'),
              SelectableText(token,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Booking status Tokens tab मध्ये तपासा.'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Done')),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $error')),
      );
    }
  }
}

class _EmptyStations extends StatelessWidget {
  const _EmptyStations();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                    color: AppColors.mint, shape: BoxShape.circle),
                child: const Icon(Icons.local_gas_station,
                    size: 42, color: AppColors.green),
              ),
              const SizedBox(height: 16),
              const Text('No CNG stations found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Try another station name or address.',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
