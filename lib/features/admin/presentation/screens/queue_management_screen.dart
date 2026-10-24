import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_colors.dart';

const Color _kEmerald = Color(0xFF07865C);
const Color _kDarkGreen = Color(0xFF075B43);
const Color _kMint = Color(0xFFE4F5EB);
const Color _kBackground = Color(0xFFF6F9F7);
const Color _kTextMain = Color(0xFF172821);
const Color _kTextSecondary = Color(0xFF718078);

class QueueManagementScreen extends StatefulWidget {
  const QueueManagementScreen({super.key});

  @override
  State<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends State<QueueManagementScreen> {
  String _filter = 'all';
  String _search = '';

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _tokensStream;
  bool? _streamIsAdmin;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _profileStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    }
  }

  /// Pump owners see tokens for their own stations (same query as before).
  /// Admins see the latest tokens across all stations.
  Stream<QuerySnapshot<Map<String, dynamic>>> _streamFor(bool isAdmin) {
    if (_tokensStream == null || _streamIsAdmin != isAdmin) {
      _streamIsAdmin = isAdmin;
      final tokens = FirebaseFirestore.instance.collection('tokens');
      // Avoid requiring a composite Firestore index for the owner query.
      // Sort the returned documents locally in _queue instead.
      _tokensStream = isAdmin
          ? tokens.orderBy('createdAt', descending: true).limit(200).snapshots()
          : tokens
              .where('stationOwnerId',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .limit(100)
              .snapshots();
    }
    return _tokensStream!;
  }

  Future<void> _setStatus(
    DocumentReference<Map<String, dynamic>> ref,
    String status,
  ) async {
    try {
      await ref.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update token: $error')),
      );
    }
  }

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
    return '${d.day} ${months[d.month - 1]}, ${two(d.hour)}:${two(d.minute)}';
  }

  Color _statusColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(title: const Text('Queue management')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileStream,
        builder: (context, profileSnapshot) {
          if (_profileStream == null) {
            return const Center(child: Text('Please sign in again.'));
          }
          if (profileSnapshot.hasError) {
            return const Center(child: Text('Could not load your account.'));
          }
          if (!profileSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = profileSnapshot.data?.data();
          final isAdmin = profile?['role'] == 'admin';
          final isApprovedOwner = profile?['role'] == 'pumpOwner' &&
              profile?['accountStatus'] == 'active' &&
              profile?['ownerApplicationStatus'] == 'approved';
          if (!isAdmin && !isApprovedOwner) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Queue management is available only to approved Pump Owners or Admins.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _queue(isAdmin);
        },
      ),
    );
  }

  Widget _queue(bool isAdmin) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _streamFor(isAdmin),
      builder: (context, s) {
        if (s.hasError) {
          return const Center(child: Text('Could not load queue.'));
        }
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          s.data!.docs,
        );
        all.sort((a, b) {
          final av = a.data()['createdAt'];
          final bv = b.data()['createdAt'];
          final am = av is Timestamp ? av.millisecondsSinceEpoch : 0;
          final bm = bv is Timestamp ? bv.millisecondsSinceEpoch : 0;
          return bm.compareTo(am);
        });
        if (all.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: _kMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.confirmation_number_outlined,
                        color: _kEmerald, size: 34),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No tokens found.',
                    style: TextStyle(
                      color: _kTextMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        int count(String status) => all
            .where((d) => (d.data()['status'] ?? 'waiting') == status)
            .length;

        final query = _search.trim().toLowerCase();
        final docs = all.where((d) {
          final x = d.data();
          final status = (x['status'] ?? 'waiting').toString();
          if (_filter != 'all' && status != _filter) return false;
          if (query.isEmpty) return true;
          final text =
              '${x['tokenNumber']} ${d.id} ${x['customerId']} ${x['stationName']} ${x['stationId']}'
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
                          hintText: 'Search token, customer or station',
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
                            borderSide:
                                const BorderSide(color: _kEmerald, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('all', 'All (${all.length})'),
                            _filterChip(
                                'waiting', 'Waiting (${count('waiting')})'),
                            _filterChip(
                                'called', 'Called (${count('called')})'),
                            _filterChip(
                                'serving', 'Serving (${count('serving')})'),
                            _filterChip('completed',
                                'Completed (${count('completed')})'),
                            _filterChip('cancelled',
                                'Cancelled (${count('cancelled')})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: docs.isEmpty
                      ? const Center(
                          child: Text(
                            'No tokens match your filters.',
                            style: TextStyle(color: _kTextSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                          itemCount: docs.length,
                          itemBuilder: (context, i) => _tokenCard(docs[i]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _tokenCard(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final x = d.data();
    final status = (x['status'] ?? 'pending').toString();
    final color = _statusColor(status);
    final created = _fmtDate(x['createdAt']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                            child: Icon(Icons.confirmation_number,
                                color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Token ${x['tokenNumber'] ?? d.id}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _kTextMain,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  x['stationName']?.toString() ??
                                      x['stationId']?.toString() ??
                                      '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _kTextSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            tooltip: 'Change status',
                            initialValue: x['status']?.toString(),
                            onSelected: (v) => _setStatus(d.reference, v),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'waiting', child: Text('Waiting')),
                              PopupMenuItem(
                                  value: 'called', child: Text('Called')),
                              PopupMenuItem(
                                  value: 'serving', child: Text('Serving')),
                              PopupMenuItem(
                                  value: 'completed', child: Text('Completed')),
                              PopupMenuItem(
                                  value: 'cancelled', child: Text('Cancelled')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down,
                                      color: color, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _infoChip(Icons.person_outline,
                              'Customer: ${x['customerId'] ?? '—'}'),
                          if (x['position'] != null)
                            _infoChip(Icons.people_outline,
                                'Position ${x['position']}'),
                          if (x['estimatedWaitMinutes'] != null)
                            _infoChip(Icons.access_time,
                                '${x['estimatedWaitMinutes']} min wait'),
                          if (created.isNotEmpty)
                            _infoChip(Icons.event_outlined, created),
                        ],
                      ),
                      if (status == 'waiting' ||
                          status == 'called' ||
                          status == 'serving') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (status == 'waiting')
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      _setStatus(d.reference, 'serving'),
                                  icon: const Icon(Icons.play_arrow_rounded,
                                      size: 20),
                                  label: const Text('Start serving'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _kEmerald,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            if (status == 'called')
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      _setStatus(d.reference, 'serving'),
                                  icon: const Icon(Icons.play_arrow_rounded,
                                      size: 20),
                                  label: const Text('Start serving'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _kEmerald,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            if (status == 'serving')
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      _setStatus(d.reference, 'completed'),
                                  icon: const Icon(Icons.check_circle_outline,
                                      size: 20),
                                  label: const Text('Mark complete'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _kEmerald,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _setStatus(d.reference, 'cancelled'),
                                icon:
                                    const Icon(Icons.cancel_outlined, size: 20),
                                label: const Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
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
