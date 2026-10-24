import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

const Color _kEmerald = Color(0xFF07865C);
const Color _kDarkGreen = Color(0xFF075B43);
const Color _kMint = Color(0xFFE4F5EB);
const Color _kBackground = Color(0xFFF6F9F7);
const Color _kTextMain = Color(0xFF172821);
const Color _kTextSecondary = Color(0xFF718078);

class PumpOwnerApplicationsScreen extends StatefulWidget {
  const PumpOwnerApplicationsScreen({super.key});

  @override
  State<PumpOwnerApplicationsScreen> createState() =>
      _PumpOwnerApplicationsScreenState();
}

class _PumpOwnerApplicationsScreenState
    extends State<PumpOwnerApplicationsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Set<String> _busy = <String>{};
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      _db.collection('pumpOwnerApplications').snapshots();
  String _search = '';

  Future<void> _review(String uid, String decision) async {
    if (decision != 'approved' && decision != 'rejected') return;

    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) {
      _message('Please log in again.');
      return;
    }

    String reviewNote = '';

    if (decision == 'rejected') {
      final controller = TextEditingController();

      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reject application'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Explain why this application is rejected',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isEmpty) return;
                Navigator.pop(dialogContext, reason);
              },
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      controller.dispose();

      if (result == null) return;

      if (result.trim().isEmpty) {
        _message('Please enter a rejection reason.');
        return;
      }

      reviewNote = result.trim();
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Approve Pump Owner?'),
          content: const Text(
            'The applicant will receive Pump Owner dashboard access.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    if (!mounted) return;

    setState(() => _busy.add(uid));

    try {
      final applicationRef = _db.collection('pumpOwnerApplications').doc(uid);
      final userRef = _db.collection('users').doc(uid);

      await _db.runTransaction<void>((transaction) async {
        // Read all documents before writing.
        final applicationSnapshot = await transaction.get(applicationRef);
        final userSnapshot = await transaction.get(userRef);

        if (!applicationSnapshot.exists || !userSnapshot.exists) {
          throw StateError(
            'Application or user profile was not found.',
          );
        }

        final application = applicationSnapshot.data()!;
        final user = userSnapshot.data()!;

        if (application['uid'] != uid || user['uid'] != uid) {
          throw StateError('Applicant information does not match.');
        }

        if (application['status'] != 'pending' ||
            user['ownerApplicationStatus'] != 'pending') {
          throw StateError(
            'This application has already been reviewed.',
          );
        }

        if (user['role'] != 'customer') {
          throw StateError(
            'Applicant account has an unexpected role.',
          );
        }

        final now = FieldValue.serverTimestamp();

        if (decision == 'approved') {
          transaction.update(userRef, {
            'role': 'pumpOwner',
            'accountStatus': 'active',
            'ownerApplicationStatus': 'approved',
            'updatedAt': now,
          });
        } else {
          transaction.update(userRef, {
            'role': 'customer',
            'ownerApplicationStatus': 'rejected',
            'updatedAt': now,
          });
        }

        transaction.update(applicationRef, {
          'status': decision,
          'reviewNote': reviewNote,
          'reviewedBy': admin.uid,
          'reviewedAt': now,
          'updatedAt': now,
        });
      });

      if (!mounted) return;

      _message(
        decision == 'approved'
            ? 'Pump Owner approved successfully.'
            : 'Application rejected.',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _message(
        error.code == 'permission-denied'
            ? 'Permission denied. Check deployed Firestore rules and Admin role.'
            : 'Review failed: ${error.message ?? error.code}',
      );
    } catch (error) {
      if (!mounted) return;
      _message('Review failed: $error');
    } finally {
      if (mounted) {
        setState(() => _busy.remove(uid));
      }
    }
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final all = snapshot.data?.docs ?? const [];
        int count(String s) => all.where((d) => d.data()['status'] == s).length;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: _kBackground,
            appBar: AppBar(
              title: const Text('Pump Owner Applications'),
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Pending (${count('pending')})'),
                  Tab(text: 'Approved (${count('approved')})'),
                  Tab(text: 'Rejected (${count('rejected')})'),
                ],
              ),
            ),
            body: _body(snapshot, all),
          ),
        );
      },
    );
  }

  Widget _body(
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> all,
  ) {
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load applications.\n${snapshot.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search by applicant, station, email or phone',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _kEmerald, width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _applicationList(all, 'pending', canReview: true),
                  _applicationList(all, 'approved'),
                  _applicationList(all, 'rejected'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _applicationList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> all,
    String status, {
    bool canReview = false,
  }) {
    final query = _search.trim().toLowerCase();
    final docs = all.where((d) {
      final x = d.data();
      if (x['status'] != status) return false;
      if (query.isEmpty) return true;
      final text =
          '${x['name']} ${x['stationName']} ${x['email']} ${x['phone']} ${x['stationAddress']}'
              .toLowerCase();
      return text.contains(query);
    }).toList();

    docs.sort((a, b) {
      final aCreated = a.data()['createdAt'];
      final bCreated = b.data()['createdAt'];

      final aDate = aCreated is Timestamp
          ? aCreated.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);

      final bDate = bCreated is Timestamp
          ? bCreated.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    if (docs.isEmpty) {
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
                child: const Icon(Icons.inbox_outlined,
                    color: _kEmerald, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                query.isEmpty
                    ? 'No $status applications'
                    : 'No matching $status applications',
                style: const TextStyle(
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return _card(doc, status, canReview);
      },
    );
  }

  Widget _card(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String status,
    bool canReview,
  ) {
    final data = doc.data();
    final busy = _busy.contains(doc.id);
    final statusColor = status == 'approved'
        ? Colors.green
        : status == 'rejected'
            ? Colors.red
            : Colors.orange;
    final submitted = _fmtDate(data['createdAt']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _kMint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_gas_station,
                    color: _kEmerald, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['stationName']?.toString() ?? 'Station application',
                      style: const TextStyle(
                        color: _kTextMain,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['name']?.toString() ?? 'Applicant',
                      style: const TextStyle(
                        color: _kTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _detail(
                  Icons.email_outlined,
                  data['email']?.toString() ?? 'Email not provided',
                ),
                _detail(
                  Icons.phone_outlined,
                  data['phone']?.toString() ?? 'Phone not provided',
                ),
                _detail(
                  Icons.location_on_outlined,
                  data['stationAddress']?.toString() ?? 'Address not provided',
                ),
                if (submitted.isNotEmpty)
                  _detail(Icons.event_outlined, 'Submitted: $submitted'),
                _detail(Icons.badge_outlined, 'Applicant UID: ${doc.id}'),
                if (data['reviewNote']?.toString().isNotEmpty == true)
                  _detail(
                    Icons.info_outline,
                    'Review note: ${data['reviewNote']}',
                  ),
              ],
            ),
          ),
          if (canReview) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : () => _review(doc.id, 'approved'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Accept'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kEmerald,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => _review(doc.id, 'rejected'),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (busy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kDarkGreen),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              text,
              style: const TextStyle(color: _kTextMain, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}
