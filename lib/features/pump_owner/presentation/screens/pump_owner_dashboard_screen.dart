import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../admin/presentation/screens/station_management_screen.dart';
import '../../../admin/presentation/screens/queue_management_screen.dart';

const Color _kEmerald = Color(0xFF07865C);
const Color _kDarkGreen = Color(0xFF075B43);
const Color _kMint = Color(0xFFE4F5EB);
const Color _kBackground = Color(0xFFF6F9F7);
const Color _kTextMain = Color(0xFF172821);
const Color _kTextSecondary = Color(0xFF718078);

/// Statistics computed only from the owner's real token documents.
class _TokenStats {
  int total = 0;
  int completed = 0;
  int cancelled = 0;
  int waiting = 0;
  int inService = 0; // called or serving
  int todayTotal = 0;
  int todayCompleted = 0;
  int todayCancelled = 0;
  final List<int> last7Days = List<int>.filled(7, 0); // index 6 = today
  final List<int> hours = List<int>.filled(24, 0);
  final List<DateTime> last7Dates = [];

  _TokenStats(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (var i = 6; i >= 0; i--) {
      last7Dates.add(today.subtract(Duration(days: i)));
    }

    for (final doc in docs) {
      final data = doc.data();
      final status = (data['status'] ?? 'waiting').toString();
      total++;
      if (status == 'completed') completed++;
      if (status == 'cancelled') cancelled++;
      if (status == 'waiting') waiting++;
      if (status == 'called' || status == 'serving') inService++;

      final created = data['createdAt'];
      if (created is! Timestamp) continue;
      final dt = created.toDate();
      hours[dt.hour]++;

      final day = DateTime(dt.year, dt.month, dt.day);
      final diff = today.difference(day).inDays;
      if (diff >= 0 && diff <= 6) last7Days[6 - diff]++;
      if (diff == 0) {
        todayTotal++;
        if (status == 'completed') todayCompleted++;
        if (status == 'cancelled') todayCancelled++;
      }
    }
  }

  int get peakHour {
    var best = 0;
    for (var h = 1; h < 24; h++) {
      if (hours[h] > hours[best]) best = h;
    }
    return best;
  }

  bool get hasHourData => hours.any((v) => v > 0);

  /// Completed as a share of finished (completed + cancelled) tokens.
  double? get completionRate {
    final finished = completed + cancelled;
    if (finished == 0) return null;
    return completed / finished;
  }
}

class PumpOwnerDashboardScreen extends StatefulWidget {
  const PumpOwnerDashboardScreen({super.key});

  @override
  State<PumpOwnerDashboardScreen> createState() =>
      _PumpOwnerDashboardScreenState();
}

class _PumpOwnerDashboardScreenState extends State<PumpOwnerDashboardScreen> {
  String? _uid;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stationsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _tokensStream;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    final uid = _uid;
    if (uid != null) {
      _profileStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
      _stationsStream = FirebaseFirestore.instance
          .collection('stations')
          .where('ownerId', isEqualTo: uid)
          .snapshots();
      _tokensStream = FirebaseFirestore.instance
          .collection('tokens')
          .where('stationOwnerId', isEqualTo: uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Pump Owner Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => AuthRepository().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileStream,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.hasError) {
            return const Center(child: Text('Could not load your account.'));
          }
          if (!profileSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = profileSnapshot.data?.data();
          if (profile == null ||
              profile['role'] != 'pumpOwner' ||
              profile['accountStatus'] != 'active' ||
              profile['ownerApplicationStatus'] != 'approved') {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Your Pump Owner account is not approved or active.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _tokensStream,
            builder: (context, tokenSnapshot) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _stationsStream,
                builder: (context, stationSnapshot) {
                  return _content(profile, tokenSnapshot, stationSnapshot);
                },
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE
  // ---------------------------------------------------------------------------

  Widget _content(
    Map<String, dynamic> profile,
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> tokenSnapshot,
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> stationSnapshot,
  ) {
    final tokenDocs = tokenSnapshot.data?.docs ?? const [];
    final stationDocs = stationSnapshot.data?.docs ?? const [];
    final stats = _TokenStats(tokenDocs);
    final tokensLoading = !tokenSnapshot.hasData && !tokenSnapshot.hasError;

    final waitingDocs = tokenDocs
        .where((d) => (d.data()['status'] ?? 'waiting') == 'waiting')
        .toList()
      ..sort((a, b) => _millis(a.data()['createdAt'])
          .compareTo(_millis(b.data()['createdAt'])));

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _banner(profile),
            const SizedBox(height: 22),
            _title('Today at a glance'),
            const SizedBox(height: 12),
            if (tokenSnapshot.hasError)
              _notice('Could not load token data; check Firestore rules.')
            else
              LayoutBuilder(
                builder: (context, c) => _metrics(
                  c.maxWidth,
                  stats,
                  stationSnapshot.hasError ? null : stationDocs.length,
                  tokensLoading,
                ),
              ),
            const SizedBox(height: 26),
            _title('Quick actions'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) => _quickActions(c.maxWidth, tokenDocs),
            ),
            const SizedBox(height: 26),
            _title('Live queue'),
            const SizedBox(height: 12),
            _liveQueue(waitingDocs, tokensLoading),
            const SizedBox(height: 26),
            _title('My stations'),
            const SizedBox(height: 12),
            _stations(stationSnapshot, stationDocs),
            const SizedBox(height: 26),
            _title('Last 7 days'),
            const SizedBox(height: 12),
            _weekChart(stats),
            const SizedBox(height: 26),
            _title('Peak hours'),
            const SizedBox(height: 12),
            _peakHours(stats),
            const SizedBox(height: 26),
            _title('Service performance'),
            const SizedBox(height: 12),
            _performance(stats),
          ],
        ),
      ),
    );
  }

  int _millis(dynamic value) =>
      value is Timestamp ? value.millisecondsSinceEpoch : 0;

  // 1. Banner ------------------------------------------------------------------

  Widget _banner(Map<String, dynamic> profile) {
    final name = (profile['name'] ?? 'Pump Owner').toString();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kEmerald, _kDarkGreen],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33075B43),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x14FFFFFF),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CNGPULSE PUMP OWNER',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome, $name',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage your station, availability and customer queue.',
                    style: TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_outlined,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Approved & active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

  // 2. Metrics -----------------------------------------------------------------

  Widget _metrics(
    double maxWidth,
    _TokenStats s,
    int? stationCount,
    bool loading,
  ) {
    const spacing = 12.0;
    final columns = maxWidth >= 700 ? 3 : 2;
    final width = (maxWidth - spacing * (columns - 1)) / columns;
    String v(int n) => loading ? '…' : '$n';

    final items = <Widget>[
      _metricCard(Icons.local_gas_station, 'My stations',
          stationCount == null ? '—' : '$stationCount'),
      _metricCard(Icons.confirmation_number_outlined, "Today's tokens",
          v(s.todayTotal)),
      _metricCard(Icons.groups_outlined, 'Waiting now', v(s.waiting)),
      _metricCard(Icons.sync_alt, 'In service', v(s.inService)),
      _metricCard(
          Icons.check_circle_outline, 'Completed today', v(s.todayCompleted)),
      _metricCard(
          Icons.cancel_outlined, 'Cancelled today', v(s.todayCancelled)),
    ];

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [for (final i in items) SizedBox(width: width, child: i)],
    );
  }

  Widget _metricCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextMain,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Quick actions -----------------------------------------------------------

  Widget _quickActions(
    double maxWidth,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> tokenDocs,
  ) {
    const spacing = 12.0;
    final columns = maxWidth >= 700 ? 3 : 1;
    final width = (maxWidth - spacing * (columns - 1)) / columns;

    final items = <Widget>[
      _actionTile(
        icon: Icons.edit_location_alt_outlined,
        title: 'My Station Management',
        subtitle: 'Add a station or update station details',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StationManagementScreen()),
        ),
      ),
      _actionTile(
        icon: Icons.confirmation_number_outlined,
        title: 'Customer Queue',
        subtitle: 'View and update customer tokens',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QueueManagementScreen()),
        ),
      ),
      _actionTile(
        icon: Icons.file_download_outlined,
        title: 'Export Tokens (CSV)',
        subtitle: 'Copy all token records to clipboard',
        onTap: () => _exportCsv(tokenDocs),
      ),
    ];

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [for (final i in items) SizedBox(width: width, child: i)],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: const Color(0x1A075B43),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _kMint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _kEmerald, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _kTextMain,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _kTextSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportCsv(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) {
      _snack('No token records to export yet.');
      return;
    }
    String esc(Object? v) {
      final s = (v ?? '').toString().replaceAll('"', '""');
      return '"$s"';
    }

    final sorted = docs.toList()
      ..sort((a, b) => _millis(b.data()['createdAt'])
          .compareTo(_millis(a.data()['createdAt'])));

    final buffer = StringBuffer(
        'Booking reference,Station,Token,Status,Queue position,Created at\n');
    for (final d in sorted) {
      final x = d.data();
      final created = x['createdAt'];
      final createdText =
          created is Timestamp ? created.toDate().toIso8601String() : '';
      buffer.writeln([
        esc(d.id),
        esc(x['stationName']),
        esc(x['tokenNumber']),
        esc(x['status']),
        esc(x['position']),
        esc(createdText),
      ].join(','));
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    _snack('${docs.length} token records copied as CSV.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 4. Live queue --------------------------------------------------------------

  Widget _liveQueue(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> waiting,
    bool loading,
  ) {
    if (loading) {
      return _shell(const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ));
    }
    if (waiting.isEmpty) {
      return _shell(_emptyState(
        Icons.groups_outlined,
        'No customers waiting',
        'New customer tokens will appear here in real time.',
      ));
    }

    final shown = waiting.take(5).toList();
    return _shell(Column(
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const Divider(height: 20),
          _queueRow(i + 1, shown[i]),
        ],
        if (waiting.length > shown.length) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '+ ${waiting.length - shown.length} more waiting',
              style: const TextStyle(
                color: _kTextSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QueueManagementScreen()),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Open Customer Queue'),
            style: TextButton.styleFrom(
              foregroundColor: _kEmerald,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ));
  }

  Widget _queueRow(
    int order,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final x = doc.data();
    final id = doc.id;
    final tokenLabel =
        x['tokenNumber'] ?? id.substring(0, id.length > 8 ? 8 : id.length);
    final wait = x['estimatedWaitMinutes'];

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _kMint,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$order',
            style: const TextStyle(
              color: _kDarkGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                x['stationName']?.toString() ?? 'CNG Station',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kTextMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Token $tokenLabel',
                style: const TextStyle(
                  color: _kTextSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        if (wait != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kMint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$wait min',
              style: const TextStyle(
                color: _kDarkGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // 5. Stations ----------------------------------------------------------------

  Widget _stations(
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (snapshot.hasError) {
      return _notice('Could not load stations; check Firestore rules.');
    }
    if (!snapshot.hasData) {
      return _shell(const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ));
    }
    if (docs.isEmpty) {
      return _shell(Column(
        children: [
          _emptyState(
            Icons.add_location_alt_outlined,
            'No stations yet',
            'Add your first station so customers can find and book it.',
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StationManagementScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add station'),
            style: FilledButton.styleFrom(backgroundColor: _kEmerald),
          ),
        ],
      ));
    }

    return Column(
      children: [for (final d in docs) _stationCard(d.data())],
    );
  }

  Widget _stationCard(Map<String, dynamic> data) {
    final active = data['active'] == true;
    final price = data['pricePerKg'];
    final availability = data['availability'];
    final queue = data['queueCount'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
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
                child: const Icon(Icons.local_gas_station,
                    color: _kEmerald, size: 24),
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
                        color: _kTextMain,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    if ((data['address'] ?? '').toString().isNotEmpty)
                      Text(
                        data['address'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kTextSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _pill(
                active ? 'ACTIVE' : 'INACTIVE',
                active ? _kEmerald : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (price != null) _infoChip(Icons.currency_rupee, '$price / kg'),
              if (queue != null)
                _infoChip(Icons.people_outline, 'Queue $queue'),
              if (availability != null)
                _infoChip(Icons.circle, availability.toString()),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Last 7 days -------------------------------------------------------------

  Widget _weekChart(_TokenStats s) {
    final maxValue = s.last7Days.reduce((a, b) => a > b ? a : b);
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (maxValue == 0) {
      return _shell(_emptyState(
        Icons.bar_chart_rounded,
        'No bookings in the last 7 days',
        'Daily token counts will appear here.',
      ));
    }

    return _shell(
      SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${s.last7Days[i]}',
                      style: const TextStyle(
                        color: _kTextMain,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: s.last7Days[i] == 0
                          ? 4
                          : 90 * s.last7Days[i] / maxValue,
                      decoration: BoxDecoration(
                        color: i == 6 ? _kEmerald : const Color(0xFF8FD3B6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i == 6 ? 'Today' : names[s.last7Dates[i].weekday - 1],
                      style: const TextStyle(
                        color: _kTextSecondary,
                        fontSize: 11,
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

  // 7. Peak hours --------------------------------------------------------------

  String _hourLabel(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  Widget _peakHours(_TokenStats s) {
    if (!s.hasHourData) {
      return _shell(_emptyState(
        Icons.schedule,
        'No booking history yet',
        'Your busiest hours will be shown once customers book tokens.',
      ));
    }
    final maxValue = s.hours.reduce((a, b) => a > b ? a : b);
    final peak = s.peakHour;

    return _shell(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department_outlined,
                color: _kEmerald, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Busiest hour: ${_hourLabel(peak)} – ${_hourLabel((peak + 1) % 24)} '
                '(${s.hours[peak]} bookings)',
                style: const TextStyle(
                  color: _kTextMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var h = 0; h < 24; h++)
              Expanded(
                child: Tooltip(
                  message: '${_hourLabel(h)}: ${s.hours[h]}',
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        _kMint,
                        _kEmerald,
                        maxValue == 0 ? 0 : s.hours[h] / maxValue,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('12 AM', style: _tinyStyle),
            Text('6 AM', style: _tinyStyle),
            Text('12 PM', style: _tinyStyle),
            Text('6 PM', style: _tinyStyle),
            Text('11 PM', style: _tinyStyle),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Based on all token bookings at your stations. Darker = busier.',
          style: TextStyle(color: _kTextSecondary, fontSize: 12),
        ),
      ],
    ));
  }

  // 8. Performance -------------------------------------------------------------

  Widget _performance(_TokenStats s) {
    final rate = s.completionRate;
    if (s.total == 0) {
      return _shell(_emptyState(
        Icons.insights_outlined,
        'No data yet',
        'Performance appears after your first customer tokens.',
      ));
    }

    return _shell(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Completion rate',
                style: TextStyle(
                  color: _kTextMain,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              rate == null ? '—' : '${(rate * 100).round()}%',
              style: const TextStyle(
                color: _kEmerald,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: rate ?? 0,
            minHeight: 10,
            backgroundColor: _kMint,
            valueColor: const AlwaysStoppedAnimation<Color>(_kEmerald),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _infoChip(
                Icons.confirmation_number_outlined, '${s.total} total tokens'),
            _infoChip(Icons.check_circle_outline, '${s.completed} completed'),
            _infoChip(Icons.cancel_outlined, '${s.cancelled} cancelled'),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Completion rate = completed ÷ (completed + cancelled).',
          style: TextStyle(color: _kTextSecondary, fontSize: 12),
        ),
      ],
    ));
  }

  // Shared helpers -------------------------------------------------------------

  static const TextStyle _tinyStyle =
      TextStyle(color: _kTextSecondary, fontSize: 10.5);

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _kTextMain,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
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

  Widget _shell(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: child,
    );
  }

  Widget _notice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _kTextMain, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: _kMint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _kEmerald, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _kTextMain,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _kTextSecondary,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kMint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kEmerald),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kTextMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
