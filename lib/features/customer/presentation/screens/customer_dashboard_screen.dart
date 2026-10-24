import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../auth/data/auth_repository.dart';
import 'stations_screen.dart';
import 'tokens_screen.dart';
import 'vehicle_screen.dart';
import 'profile_screen.dart';
import 'customer_features_screen.dart';

// Palette for the Home redesign (local to this file).
const Color _kEmerald = Color(0xFF07865C);
const Color _kDarkGreen = Color(0xFF075B43);
const Color _kMint = Color(0xFFE4F5EB);
const Color _kBackground = Color(0xFFF6F9F7);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kTextMain = Color(0xFF172821);
const Color _kTextSecondary = Color(0xFF718078);

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _tab = 0;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _tokensStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _profileStream = FirestoreService().watchMyProfile();
      // Same query the Tokens tab uses.
      _tokensStream = FirebaseFirestore.instance
          .collection('tokens')
          .where('customerId', isEqualTo: uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _home(),
      const StationsScreen(),
      const TokensScreen(),
      const VehicleScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CNGPulse'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await AuthRepository().logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() => _tab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'Stations',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            label: 'Tokens',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            label: 'Vehicle',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HOME TAB
  // ---------------------------------------------------------------------------

  Widget _home() {
    return Container(
      color: _kBackground,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              _header(),
              const SizedBox(height: 20),
              _heroBanner(),
              const SizedBox(height: 28),
              const SectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) =>
                    _quickActions(constraints.maxWidth),
              ),
              const SizedBox(height: 28),
              const SectionTitle('Booking Summary'),
              const SizedBox(height: 12),
              _bookingSummary(),
              const SizedBox(height: 28),
              const SectionTitle('Helpful Information'),
              const SizedBox(height: 12),
              _helpCard(),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Header ------------------------------------------------------------------

  Widget _header() {
    final stream = _profileStream;
    if (stream == null) return _headerContent(null);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final raw = snapshot.data?.data()?['name']?.toString().trim();
        final name = (raw != null && raw.isNotEmpty)
            ? raw
            : FirebaseAuth.instance.currentUser?.displayName?.trim();
        return _headerContent(name);
      },
    );
  }

  Widget _headerContent(String? name) {
    final hasName = name != null && name.isNotEmpty;
    final greeting = hasName ? 'Hello, $name' : 'Hello';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kTextMain,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ready for your next journey?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _kTextSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () => setState(() => _tab = 4),
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kMint,
              shape: BoxShape.circle,
              border: Border.all(color: _kEmerald, width: 1.5),
            ),
            child: hasName
                ? Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: _kDarkGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : const Icon(Icons.person_outline, color: _kDarkGreen),
          ),
        ),
      ],
    );
  }

  // 2. Hero banner ---------------------------------------------------------------

  Widget _heroBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kEmerald, _kDarkGreen],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33075B43),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x14FFFFFF),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -50,
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0FFFFFFF),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR NEXT STOP, SIMPLIFIED',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Fuel Up Smarter.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Find nearby CNG stations and plan your visit '
                    'with less waiting.',
                    style: TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _tab = 1),
                    icon: const Icon(Icons.local_gas_station_rounded, size: 20),
                    label: const Text('Find CNG Stations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _kDarkGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Quick actions (no fixed aspect ratio, so it can never overflow) ----------

  Widget _quickActions(double maxWidth) {
    const spacing = 12.0;
    final columns = maxWidth >= 600 ? 4 : 2;
    final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

    final items = <Widget>[
      _action(
        Icons.location_on_outlined,
        'Find Stations',
        'Explore CNG stations',
        () => setState(() => _tab = 1),
      ),
      _action(
        Icons.confirmation_number_outlined,
        'My Tokens',
        'Check queue status',
        () => setState(() => _tab = 2),
      ),
      _action(
        Icons.directions_car_outlined,
        'My Vehicle',
        'Manage vehicle',
        () => setState(() => _tab = 3),
      ),
      _action(
        Icons.account_circle_outlined,
        'My Profile',
        'Account details',
        () => setState(() => _tab = 4),
      ),
      _action(
        Icons.widgets_outlined,
        'Customer Services',
        'Mileage, reminders, reviews & more',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CustomerFeaturesScreen(),
          ),
        ),
      ),
    ];

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final item in items) SizedBox(width: cardWidth, child: item),
      ],
    );
  }

  Widget _action(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: _kCard,
      elevation: 1.5,
      shadowColor: const Color(0x1A075B43),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _kEmerald, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kTextMain,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _kTextSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Booking summary (real tokens only) ----------------------------------------

  Widget _bookingSummary() {
    final stream = _tokensStream;
    if (stream == null) {
      return _bookingShell(_bookingEmpty());
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _bookingShell(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Could not load your bookings right now.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTextSecondary),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return _bookingShell(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aa = a.data()['createdAt'];
            final bb = b.data()['createdAt'];
            final at = aa is Timestamp ? aa.millisecondsSinceEpoch : 0;
            final bt = bb is Timestamp ? bb.millisecondsSinceEpoch : 0;
            return bt.compareTo(at);
          });

        if (docs.isEmpty) return _bookingShell(_bookingEmpty());
        return _bookingShell(_bookingFilled(docs.first));
      },
    );
  }

  Widget _bookingShell(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: child,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      case 'serving':
        return Colors.orange;
      default:
        return _kEmerald;
    }
  }

  Widget _bookingFilled(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final station = (data['stationName'] ?? 'CNG Station').toString();
    final status = (data['status'] ?? 'waiting').toString();
    final color = _statusColor(status);

    final details = <String>[];
    if (data['tokenNumber'] != null) {
      details.add('Token ${data['tokenNumber']}');
    }
    if (data['position'] != null) {
      details.add('Queue position ${data['position']}');
    }
    if (data['estimatedWaitMinutes'] != null) {
      details.add('Est. wait ${data['estimatedWaitMinutes']} min');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kMint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_gas_station_outlined,
                color: _kEmerald,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kTextMain,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            details.join('  •  '),
            style: const TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
        ],
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => setState(() => _tab = 2),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('View My Tokens'),
          style: TextButton.styleFrom(
            foregroundColor: _kEmerald,
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _bookingEmpty() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: _kMint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.event_available_outlined,
            color: _kEmerald,
            size: 28,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'No bookings yet',
          style: TextStyle(
            color: _kTextMain,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your latest booking will appear here once you book a token '
          'at a station.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _kTextSecondary, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => setState(() => _tab = 1),
          icon: const Icon(Icons.location_on_outlined, size: 18),
          label: const Text('Find Stations'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kEmerald,
            side: const BorderSide(color: _kEmerald),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // 5. Helpful information -------------------------------------------------------

  Widget _helpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          _InfoRow(
            icon: Icons.search_rounded,
            title: 'Find stations',
            subtitle: 'Explore nearby CNG stations in one place.',
          ),
          SizedBox(height: 14),
          _InfoRow(
            icon: Icons.confirmation_number_outlined,
            title: 'Book tokens',
            subtitle: 'Reserve your visit to reduce waiting time.',
          ),
          SizedBox(height: 14),
          _InfoRow(
            icon: Icons.query_stats,
            title: 'Check queue status',
            subtitle: 'Queue and availability depend on updates provided '
                'by station operators.',
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F075B43),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kMint,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _kEmerald, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _kTextMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _kTextSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
