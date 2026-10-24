import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import 'station_management_screen.dart';
import 'queue_management_screen.dart';
import 'pump_owner_applications_screen.dart';

const Color _kEmerald = Color(0xFF07865C);
const Color _kDarkGreen = Color(0xFF075B43);
const Color _kMint = Color(0xFFE4F5EB);
const Color _kBackground = Color(0xFFF6F9F7);
const Color _kTextMain = Color(0xFF172821);
const Color _kTextSecondary = Color(0xFF718078);

typedef _QS = QuerySnapshot<Map<String, dynamic>>;
typedef _Docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;

// -----------------------------------------------------------------------------
// Shared helpers
// -----------------------------------------------------------------------------

int _millis(dynamic v) => v is Timestamp ? v.millisecondsSinceEpoch : 0;

String _fmtDate(dynamic v) {
  if (v is! Timestamp) return '';
  final d = v.toDate();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} ${d.year}, ${two(d.hour)}:${two(d.minute)}';
}

String _hourLabel(int h) {
  if (h == 0) return '12 AM';
  if (h < 12) return '$h AM';
  if (h == 12) return '12 PM';
  return '${h - 12} PM';
}

String _csvCell(Object? v) {
  final s =
      v is Timestamp ? v.toDate().toIso8601String() : (v ?? '').toString();
  return '"${s.replaceAll('"', '""')}"';
}

String _complaintGroup(dynamic status) {
  final v = (status ?? 'open').toString().toLowerCase().replaceAll(' ', '_');
  if (v == 'resolved' || v == 'closed') return 'resolved';
  if (v == 'in_progress' || v == 'reviewing') return 'in_progress';
  return 'open';
}

Color _tokenStatusColor(String status) {
  switch (status) {
    case 'completed':
      return Colors.green;
    case 'cancelled':
      return Colors.grey;
    case 'serving':
      return Colors.orange;
    case 'called':
      return Colors.blue;
    default:
      return _kEmerald;
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
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

Widget _pill(String label, Color color) => Container(
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

Widget _infoChip(IconData icon, String label) => Container(
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

Widget _emptyState(IconData icon, String title, String subtitle) => Column(
      mainAxisSize: MainAxisSize.min,
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

/// Statistics computed only from real token documents.
class _AdminStats {
  int total = 0;
  int completed = 0;
  int cancelled = 0;
  int waiting = 0;
  int inService = 0;
  int todayTotal = 0;
  final List<int> last7Days = List<int>.filled(7, 0);
  final List<int> hours = List<int>.filled(24, 0);
  final List<DateTime> last7Dates = [];
  final Map<String, int> perStation = {};

  _AdminStats(_Docs docs) {
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

      final station =
          (data['stationName'] ?? data['stationId'] ?? 'Unknown').toString();
      perStation[station] = (perStation[station] ?? 0) + 1;

      final created = data['createdAt'];
      if (created is! Timestamp) continue;
      final dt = created.toDate();
      hours[dt.hour]++;
      final diff = today.difference(DateTime(dt.year, dt.month, dt.day)).inDays;
      if (diff >= 0 && diff <= 6) last7Days[6 - diff]++;
      if (diff == 0) todayTotal++;
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

  double? get completionRate {
    final finished = completed + cancelled;
    return finished == 0 ? null : completed / finished;
  }
}

// -----------------------------------------------------------------------------
// Dashboard
// -----------------------------------------------------------------------------

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String? _uid;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;
  Stream<_QS>? _tokensStream; // last 30 days
  Stream<_QS>? _stationsStream;
  Stream<_QS>? _appsStream;
  Stream<_QS>? _complaintsStream;
  Stream<_QS>? _usersStream;
  Stream<_QS>? _ownerStationsStream;
  Stream<_QS>? _ownerWaitingStream;

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _uid = uid;
    if (uid == null) return;

    final since = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 30)),
    );
    _profileStream = db.collection('users').doc(uid).snapshots();
    _tokensStream = db
        .collection('tokens')
        .where('createdAt', isGreaterThanOrEqualTo: since)
        .snapshots();
    _stationsStream = db.collection('stations').snapshots();
    _appsStream = db.collection('pumpOwnerApplications').snapshots();
    _complaintsStream = db.collection('complaints').snapshots();
    _usersStream = db.collection('users').snapshots();
    _ownerStationsStream =
        db.collection('stations').where('ownerId', isEqualTo: uid).snapshots();
    _ownerWaitingStream = db
        .collection('tokens')
        .where('stationOwnerId', isEqualTo: uid)
        .where('status', isEqualTo: 'waiting')
        .snapshots();
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profileStream,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Could not load account profile.')),
          );
        }
        if (!profileSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = profileSnapshot.data?.data();
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Account profile not found.')),
          );
        }
        final isAdmin = profile['role'] == 'admin';

        return Scaffold(
          backgroundColor: _kBackground,
          appBar: AppBar(
            title: Text(isAdmin ? 'CNGPulse Admin' : 'Pump Owner Dashboard'),
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
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: isAdmin ? _adminBody() : _ownerBody(),
            ),
          ),
        );
      },
    );
  }

  Widget _sb(Stream<_QS>? stream, Widget Function(AsyncSnapshot<_QS>) build) {
    return StreamBuilder<_QS>(
      stream: stream,
      builder: (context, snapshot) => build(snapshot),
    );
  }

  // ---------------------------------------------------------------------------
  // ADMIN
  // ---------------------------------------------------------------------------

  Widget _adminBody() {
    return _sb(
      _tokensStream,
      (t) => _sb(
        _stationsStream,
        (s) => _sb(
          _appsStream,
          (a) => _sb(
            _complaintsStream,
            (c) => _sb(_usersStream, (u) => _adminContent(t, s, a, c, u)),
          ),
        ),
      ),
    );
  }

  Widget _adminContent(
    AsyncSnapshot<_QS> t,
    AsyncSnapshot<_QS> s,
    AsyncSnapshot<_QS> a,
    AsyncSnapshot<_QS> c,
    AsyncSnapshot<_QS> u,
  ) {
    final tokenDocs = t.data?.docs ?? const [];
    final stationDocs = s.data?.docs ?? const [];
    final appDocs = a.data?.docs ?? const [];
    final complaintDocs = c.data?.docs ?? const [];
    final userDocs = u.data?.docs ?? const [];
    final stats = _AdminStats(tokenDocs);

    final pending =
        appDocs.where((d) => d.data()['status'] == 'pending').length;
    final approved =
        appDocs.where((d) => d.data()['status'] == 'approved').length;
    final rejected =
        appDocs.where((d) => d.data()['status'] == 'rejected').length;
    final openComplaints = complaintDocs
        .where((d) => _complaintGroup(d.data()['status']) != 'resolved')
        .length;
    final customers =
        userDocs.where((d) => d.data()['role'] == 'customer').length;
    final owners =
        userDocs.where((d) => d.data()['role'] == 'pumpOwner').length;
    final activeStations =
        stationDocs.where((d) => d.data()['active'] == true).length;

    final tokensLoading = !t.hasData && !t.hasError;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _banner(),
        const SizedBox(height: 18),
        _attention(pending, openComplaints, a.hasError, c.hasError),
        const SizedBox(height: 24),
        _title('Platform overview'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, cons) => _overview(
            cons.maxWidth,
            customers: u.hasError ? null : customers,
            owners: u.hasError ? null : owners,
            activeStations: s.hasError ? null : activeStations,
            totalStations: s.hasError ? null : stationDocs.length,
            tokensToday: t.hasError || tokensLoading ? null : stats.todayTotal,
            waiting: t.hasError || tokensLoading ? null : stats.waiting,
            openComplaints: c.hasError ? null : openComplaints,
            inService: t.hasError || tokensLoading ? null : stats.inService,
            pending: a.hasError ? null : pending,
          ),
        ),
        const SizedBox(height: 24),
        _title('Pump owner applications'),
        const SizedBox(height: 12),
        _applicationsRow(pending, approved, rejected, a.hasError),
        const SizedBox(height: 24),
        _title('Management'),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, cons) => _actions(cons.maxWidth)),
        const SizedBox(height: 24),
        _title('Bookings – last 7 days'),
        const SizedBox(height: 12),
        _weekChart(stats, t.hasError),
        const SizedBox(height: 24),
        _title('Peak hours'),
        const SizedBox(height: 12),
        _peakHours(stats),
        const SizedBox(height: 24),
        _title('Station network'),
        const SizedBox(height: 12),
        _network(stationDocs, s.hasError),
        const SizedBox(height: 24),
        _title('Top stations by bookings'),
        const SizedBox(height: 12),
        _topStations(stats),
        const SizedBox(height: 24),
        _title('Queue performance'),
        const SizedBox(height: 12),
        _performance(stats),
        const SizedBox(height: 24),
        _title('Recent activity'),
        const SizedBox(height: 12),
        _recent(tokenDocs),
        const SizedBox(height: 12),
        const Text(
          'Booking analytics use token data from the last 30 days.',
          style: TextStyle(color: _kTextSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _title(String text) => Text(
        text,
        style: const TextStyle(
          color: _kTextMain,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      );

  Widget _shell(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: child,
      );

  Widget _banner() {
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
            const Padding(
              padding: EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CNGPULSE ADMIN',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Administration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Review applications and oversee stations, queues and operations.',
                    style: TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontSize: 14,
                      height: 1.4,
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

  Widget _attention(int pending, int openComplaints, bool appsErr, bool cErr) {
    final items = <Widget>[];
    if (pending > 0 && !appsErr) {
      items.add(_attentionRow(
        Icons.hourglass_top,
        Colors.orange,
        '$pending pump owner application${pending == 1 ? '' : 's'} awaiting review',
        'Review',
        () => _open(const PumpOwnerApplicationsScreen()),
      ));
    }
    if (openComplaints > 0 && !cErr) {
      items.add(_attentionRow(
        Icons.report_problem_outlined,
        Colors.red,
        '$openComplaints unresolved complaint${openComplaints == 1 ? '' : 's'}',
        'Open',
        () => _open(const _ComplaintsScreen()),
      ));
    }

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kMint,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: _kEmerald),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'All caught up – nothing needs your attention right now.',
                style: TextStyle(
                  color: _kDarkGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE2B8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Needs attention',
            style: TextStyle(
              color: _kTextMain,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ...items,
        ],
      ),
    );
  }

  Widget _attentionRow(
    IconData icon,
    Color color,
    String text,
    String button,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _kTextMain, fontSize: 13.5),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(foregroundColor: _kEmerald),
            child: Text(button),
          ),
        ],
      ),
    );
  }

  // Overview metrics -----------------------------------------------------------

  Widget _overview(
    double maxWidth, {
    required int? customers,
    required int? owners,
    required int? activeStations,
    required int? totalStations,
    required int? tokensToday,
    required int? waiting,
    required int? openComplaints,
    required int? inService,
    required int? pending,
  }) {
    const spacing = 12.0;
    final columns = maxWidth >= 700 ? 3 : 2;
    final width = (maxWidth - spacing * (columns - 1)) / columns;
    String v(int? n) => n == null ? '—' : '$n';

    final items = <Widget>[
      _metricCard(Icons.people_alt_outlined, 'Customers', v(customers)),
      _metricCard(Icons.badge_outlined, 'Pump owners', v(owners)),
      _metricCard(
        Icons.local_gas_station,
        'Active stations',
        activeStations == null
            ? '—'
            : '$activeStations / ${totalStations ?? 0}',
      ),
      _metricCard(
          Icons.confirmation_number_outlined, "Today's tokens", v(tokensToday)),
      _metricCard(Icons.groups_outlined, 'Waiting now', v(waiting)),
      _metricCard(Icons.sync_alt, 'In service', v(inService)),
      _metricCard(Icons.hourglass_top, 'Pending applications', v(pending)),
      _metricCard(
          Icons.report_problem_outlined, 'Open complaints', v(openComplaints)),
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
                  style: const TextStyle(color: _kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationsRow(int pending, int approved, int rejected, bool err) {
    if (err) {
      return _shell(const Text('Could not load application metrics.'));
    }
    Widget cell(String label, int value, IconData icon, Color color) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(const PumpOwnerApplicationsScreen()),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 10),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: _kTextMain,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: _kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        cell('Pending', pending, Icons.hourglass_top, Colors.orange),
        const SizedBox(width: 10),
        cell('Approved', approved, Icons.verified, Colors.green),
        const SizedBox(width: 10),
        cell('Rejected', rejected, Icons.block, Colors.red),
      ],
    );
  }

  // Management actions -----------------------------------------------------------

  Widget _actions(double maxWidth) {
    const spacing = 12.0;
    final columns = maxWidth >= 700 ? 3 : 2;
    final width = (maxWidth - spacing * (columns - 1)) / columns;

    final items = <Widget>[
      _actionCard(
        Icons.verified_user_outlined,
        'Applications',
        'Accept or reject owners',
        () => _open(const PumpOwnerApplicationsScreen()),
      ),
      _actionCard(
        Icons.local_gas_station_outlined,
        'All Stations',
        'Listings & availability',
        () => _open(const StationManagementScreen()),
      ),
      _actionCard(
        Icons.confirmation_number_outlined,
        'Queue Management',
        'View & update tokens',
        () => _open(const QueueManagementScreen()),
      ),
      _actionCard(
        Icons.report_problem_outlined,
        'Complaints',
        'Review & resolve',
        () => _open(const _ComplaintsScreen()),
      ),
      _actionCard(
        Icons.people_alt_outlined,
        'Users',
        'Customers & owners',
        () => _open(const _UsersScreen()),
      ),
      _actionCard(
        Icons.file_download_outlined,
        'Export Reports',
        'Copy data as CSV',
        _showExportSheet,
      ),
    ];

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [for (final i in items) SizedBox(width: width, child: i)],
    );
  }

  Widget _actionCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
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

  // Export -----------------------------------------------------------------------

  static const Map<String, List<String>> _exportFields = {
    'stations': [
      'name',
      'address',
      'pricePerKg',
      'queueCount',
      'availability',
      'active',
      'ownerId',
    ],
    'tokens': [
      'tokenNumber',
      'stationName',
      'stationId',
      'customerId',
      'status',
      'position',
      'estimatedWaitMinutes',
      'createdAt',
    ],
    'pumpOwnerApplications': [
      'name',
      'email',
      'phone',
      'stationName',
      'stationAddress',
      'status',
      'reviewNote',
      'createdAt',
    ],
    'complaints': [
      'subject',
      'category',
      'description',
      'customerId',
      'status',
      'createdAt',
    ],
  };

  void _showExportSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget tile(String label, String collection, IconData icon) {
          return ListTile(
            leading: Icon(icon, color: _kEmerald),
            title: Text(label),
            subtitle: const Text('Copies CSV to clipboard'),
            onTap: () {
              Navigator.pop(sheetContext);
              _exportCollection(collection);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Export report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              tile('Stations', 'stations', Icons.local_gas_station_outlined),
              tile('Tokens (latest 1000)', 'tokens',
                  Icons.confirmation_number_outlined),
              tile('Pump owner applications', 'pumpOwnerApplications',
                  Icons.verified_user_outlined),
              tile('Complaints', 'complaints', Icons.report_problem_outlined),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportCollection(String collection) async {
    final fields = _exportFields[collection]!;
    try {
      Query<Map<String, dynamic>> query =
          FirebaseFirestore.instance.collection(collection);
      if (collection == 'tokens') {
        query = query.orderBy('createdAt', descending: true).limit(1000);
      }
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        _snack('Nothing to export for $collection yet.');
        return;
      }
      final buffer = StringBuffer('id,${fields.join(',')}\n');
      for (final d in snapshot.docs) {
        final data = d.data();
        buffer.writeln(
          [_csvCell(d.id), ...fields.map((f) => _csvCell(data[f]))].join(','),
        );
      }
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      _snack('${snapshot.docs.length} $collection records copied as CSV.');
    } catch (error) {
      _snack('Export failed: $error');
    }
  }

  // Charts -----------------------------------------------------------------------

  Widget _weekChart(_AdminStats s, bool err) {
    if (err) return _shell(const Text('Could not load booking data.'));
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

  Widget _peakHours(_AdminStats s) {
    if (!s.hasHourData) {
      return _shell(_emptyState(
        Icons.schedule,
        'No booking history yet',
        'Platform-wide busiest hours will be shown here.',
      ));
    }
    final maxValue = s.hours.reduce((a, b) => a > b ? a : b);
    final peak = s.peakHour;
    const tiny = TextStyle(color: _kTextSecondary, fontSize: 10.5);

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
            Text('12 AM', style: tiny),
            Text('6 AM', style: tiny),
            Text('12 PM', style: tiny),
            Text('6 PM', style: tiny),
            Text('11 PM', style: tiny),
          ],
        ),
      ],
    ));
  }

  // Station network ----------------------------------------------------------------

  Widget _network(_Docs stations, bool err) {
    if (err) return _shell(const Text('Could not load stations.'));
    if (stations.isEmpty) {
      return _shell(_emptyState(
        Icons.local_gas_station_outlined,
        'No stations yet',
        'Stations added by pump owners will appear here.',
      ));
    }
    var available = 0, limited = 0, unavailable = 0, unknown = 0;
    var inactive = 0;
    for (final d in stations) {
      final x = d.data();
      if (x['active'] != true) inactive++;
      switch ((x['availability'] ?? '').toString()) {
        case 'available':
          available++;
          break;
        case 'limited':
          limited++;
          break;
        case 'unavailable':
          unavailable++;
          break;
        default:
          unknown++;
      }
    }
    final segments = <MapEntry<Color, int>>[
      MapEntry(Colors.green, available),
      MapEntry(Colors.orange, limited),
      MapEntry(Colors.red, unavailable),
      MapEntry(Colors.grey, unknown),
    ].where((e) => e.value > 0).toList();

    return _shell(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final seg in segments)
                  Expanded(
                    flex: seg.value,
                    child: Container(color: seg.key),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _infoChip(Icons.circle, '$available available'),
            _infoChip(Icons.circle, '$limited limited'),
            _infoChip(Icons.circle, '$unavailable unavailable'),
            if (unknown > 0)
              _infoChip(Icons.help_outline, '$unknown not reported'),
            _infoChip(Icons.visibility_off_outlined, '$inactive inactive'),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Availability is reported by station operators.',
          style: TextStyle(color: _kTextSecondary, fontSize: 12),
        ),
      ],
    ));
  }

  Widget _topStations(_AdminStats s) {
    if (s.perStation.isEmpty) {
      return _shell(_emptyState(
        Icons.leaderboard_outlined,
        'No bookings yet',
        'Your busiest stations will be ranked here.',
      ));
    }
    final entries = s.perStation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final maxValue = top.first.value;

    return _shell(Column(
      children: [
        for (var i = 0; i < top.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _kMint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: _kDarkGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      top[i].key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextMain,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: top[i].value / maxValue,
                        minHeight: 8,
                        backgroundColor: _kMint,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_kEmerald),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${top[i].value}',
                style: const TextStyle(
                  color: _kTextMain,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ],
    ));
  }

  Widget _performance(_AdminStats s) {
    if (s.total == 0) {
      return _shell(_emptyState(
        Icons.insights_outlined,
        'No data yet',
        'Queue performance appears after customers book tokens.',
      ));
    }
    final rate = s.completionRate;
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
            _infoChip(Icons.confirmation_number_outlined, '${s.total} tokens'),
            _infoChip(Icons.check_circle_outline, '${s.completed} completed'),
            _infoChip(Icons.cancel_outlined, '${s.cancelled} cancelled'),
            _infoChip(Icons.groups_outlined, '${s.waiting} waiting'),
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

  Widget _recent(_Docs tokenDocs) {
    if (tokenDocs.isEmpty) {
      return _shell(_emptyState(
        Icons.history,
        'No recent activity',
        'Latest customer tokens will be listed here.',
      ));
    }
    final sorted = tokenDocs.toList()
      ..sort((a, b) => _millis(b.data()['createdAt'])
          .compareTo(_millis(a.data()['createdAt'])));
    final shown = sorted.take(6).toList();

    return _shell(Column(
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const Divider(height: 20),
          _recentRow(shown[i]),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _open(const QueueManagementScreen()),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Open Queue Management'),
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

  Widget _recentRow(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final x = d.data();
    final status = (x['status'] ?? 'waiting').toString();
    final label = x['tokenNumber'] ??
        d.id.substring(0, d.id.length > 8 ? 8 : d.id.length);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _kMint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.confirmation_number_outlined,
              color: _kEmerald, size: 20),
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
                'Token $label  •  ${_fmtDate(x['createdAt'])}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _kTextSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _pill(status.toUpperCase(), _tokenStatusColor(status)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PUMP OWNER (kept for non-admin accounts that reach this screen)
  // ---------------------------------------------------------------------------

  Widget _ownerBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kEmerald, _kDarkGreen],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CNGPULSE PUMP OWNER',
                style: TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Station Operations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manage your station, availability and customer queues.',
                style: TextStyle(color: Color(0xE6FFFFFF)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _sb(
                _ownerStationsStream,
                (s) => _metricCard(
                  Icons.local_gas_station,
                  'Stations',
                  s.hasError ? '—' : '${s.data?.docs.length ?? 0}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _sb(
                _ownerWaitingStream,
                (t) => _metricCard(
                  Icons.groups_outlined,
                  'Waiting tokens',
                  t.hasError ? '—' : '${t.data?.docs.length ?? 0}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ownerTile(
          Icons.edit_location_alt_outlined,
          'Station Management',
          'Add your station and update prices',
          () => _open(const StationManagementScreen()),
        ),
        _ownerTile(
          Icons.confirmation_number_outlined,
          'Queue Management',
          'View and update customer tokens',
          () => _open(const QueueManagementScreen()),
        ),
      ],
    );
  }

  Widget _ownerTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kMint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _kEmerald),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _kTextMain,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _kTextSecondary,
                          fontSize: 12.5,
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
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Complaints
// -----------------------------------------------------------------------------

class _ComplaintsScreen extends StatefulWidget {
  const _ComplaintsScreen();

  @override
  State<_ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<_ComplaintsScreen> {
  String _filter = 'all';
  String _search = '';

  Future<void> _setStatus(
    DocumentReference<Map<String, dynamic>> ref,
    String status,
  ) async {
    try {
      await ref.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint status updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update complaint: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(title: const Text('Customer Complaints')),
      body: StreamBuilder<_QS>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load complaints. Check Firestore rules/indexes.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!.docs;
          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _emptyState(
                  Icons.sentiment_satisfied_alt_outlined,
                  'No complaints found',
                  'Customer complaints will appear here.',
                ),
              ),
            );
          }

          int count(String g) =>
              all.where((d) => _complaintGroup(d.data()['status']) == g).length;

          final query = _search.trim().toLowerCase();
          final docs = all.where((d) {
            final x = d.data();
            if (_filter != 'all' && _complaintGroup(x['status']) != _filter) {
              return false;
            }
            if (query.isEmpty) return true;
            final text =
                '${x['subject']} ${x['category']} ${x['description']} ${x['customerId']}'
                    .toLowerCase();
            return text.contains(query);
          }).toList();

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (v) => setState(() => _search = v),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search complaints',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: _kEmerald, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip('all', 'All (${all.length})'),
                              _filterChip('open', 'Open (${count('open')})'),
                              _filterChip('in_progress',
                                  'In progress (${count('in_progress')})'),
                              _filterChip('resolved',
                                  'Resolved (${count('resolved')})'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: docs.isEmpty
                        ? Center(
                            child: _emptyState(
                              Icons.search_off,
                              'No matching complaints',
                              'Try another filter or search term.',
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                            itemCount: docs.length,
                            itemBuilder: (context, i) => _card(docs[i]),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: _kMint,
        labelStyle: TextStyle(
          color: selected ? _kDarkGreen : _kTextSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        side: BorderSide(color: selected ? _kEmerald : AppColors.border),
        showCheckmark: false,
      ),
    );
  }

  Widget _card(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final x = doc.data();
    final group = _complaintGroup(x['status']);
    final color = group == 'resolved'
        ? Colors.green
        : group == 'in_progress'
            ? Colors.orange
            : Colors.red;
    final label = group == 'in_progress'
        ? 'IN PROGRESS'
        : (x['status']?.toString() ?? 'open').toUpperCase();
    final description = (x['description'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.report_problem_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      x['subject']?.toString() ??
                          x['category']?.toString() ??
                          'Customer complaint',
                      style: const TextStyle(
                        color: _kTextMain,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (x['category'] != null && x['subject'] != null)
                      Text(
                        x['category'].toString(),
                        style: const TextStyle(
                          color: _kTextSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _pill(label, color),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                color: _kTextMain,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Customer: ${x['customerId'] ?? '—'}'
            '${_fmtDate(x['createdAt']).isEmpty ? '' : '  •  ${_fmtDate(x['createdAt'])}'}',
            style: const TextStyle(color: _kTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (group != 'in_progress')
                OutlinedButton(
                  onPressed: () => _setStatus(doc.reference, 'in_progress'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                    side: BorderSide(color: Colors.orange.shade300),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Mark in progress'),
                ),
              if (group != 'resolved')
                FilledButton(
                  onPressed: () => _setStatus(doc.reference, 'resolved'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kEmerald,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Mark resolved'),
                ),
              if (group == 'resolved')
                OutlinedButton(
                  onPressed: () => _setStatus(doc.reference, 'open'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Reopen'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Users directory (read-only)
// -----------------------------------------------------------------------------

class _UsersScreen extends StatefulWidget {
  const _UsersScreen();

  @override
  State<_UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<_UsersScreen> {
  String _filter = 'all';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(title: const Text('Users')),
      body: StreamBuilder<_QS>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load users. Check Firestore rules for admin access.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!.docs;
          int count(String role) =>
              all.where((d) => d.data()['role'] == role).length;

          final query = _search.trim().toLowerCase();
          final docs = all.where((d) {
            final x = d.data();
            if (_filter != 'all' && x['role'] != _filter) return false;
            if (query.isEmpty) return true;
            return '${x['name']} ${x['email']} ${x['phone']}'
                .toLowerCase()
                .contains(query);
          }).toList()
            ..sort((a, b) => (a.data()['name'] ?? '')
                .toString()
                .toLowerCase()
                .compareTo((b.data()['name'] ?? '').toString().toLowerCase()));

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (v) => setState(() => _search = v),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search by name, email or phone',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: _kEmerald, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip('all', 'All (${all.length})'),
                              _filterChip('customer',
                                  'Customers (${count('customer')})'),
                              _filterChip('pumpOwner',
                                  'Pump owners (${count('pumpOwner')})'),
                              _filterChip(
                                  'admin', 'Admins (${count('admin')})'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: docs.isEmpty
                        ? Center(
                            child: _emptyState(
                              Icons.search_off,
                              'No users found',
                              'Try another filter or search term.',
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                            itemCount: docs.length,
                            itemBuilder: (context, i) =>
                                _userCard(docs[i].data()),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: _kMint,
        labelStyle: TextStyle(
          color: selected ? _kDarkGreen : _kTextSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        side: BorderSide(color: selected ? _kEmerald : AppColors.border),
        showCheckmark: false,
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> x) {
    final name = (x['name'] ?? 'Unnamed user').toString();
    final role = (x['role'] ?? 'unknown').toString();
    final status = (x['accountStatus'] ?? '').toString();
    final roleLabel = role == 'pumpOwner' ? 'PUMP OWNER' : role.toUpperCase();
    final roleColor = role == 'admin'
        ? Colors.purple
        : role == 'pumpOwner'
            ? Colors.orange
            : _kEmerald;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _kMint,
              shape: BoxShape.circle,
            ),
            child: Text(
              name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
              style: const TextStyle(
                color: _kDarkGreen,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((x['email'] ?? '').toString().isNotEmpty)
                  Text(
                    x['email'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kTextSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                if ((x['phone'] ?? '').toString().isNotEmpty)
                  Text(
                    x['phone'].toString(),
                    style: const TextStyle(
                      color: _kTextSecondary,
                      fontSize: 12.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _pill(roleLabel, roleColor),
              if (status.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  status,
                  style: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
