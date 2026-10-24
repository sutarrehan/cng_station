import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firestore_service.dart';

class TokensScreen extends StatelessWidget {
  const TokensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Please sign in.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tokens')
          .where('customerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not load tokens. Check Firestore rules/indexes.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aa = a.data()['createdAt'];
            final bb = b.data()['createdAt'];
            final at = aa is Timestamp ? aa.millisecondsSinceEpoch : 0;
            final bt = bb is Timestamp ? bb.millisecondsSinceEpoch : 0;
            return bt.compareTo(at);
          });

        if (docs.isEmpty) return const _EmptyTokens();

        return Container(
          color: AppColors.background,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  const Text(
                    'My tokens',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Queue status Firestore मधून real-time update होतो.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  ...docs.map((d) => _tokenCard(context, d)),
                ],
              ),
            ),
          ),
        );
      },
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
        return AppColors.green;
    }
  }

  Widget _tokenCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final x = d.data();
    final status = (x['status'] ?? 'waiting').toString();
    final canCancel = status == 'waiting';
    final color = _statusColor(status);
    final tokenLabel = x['tokenNumber'] ??
        d.id.substring(0, d.id.length > 8 ? 8 : d.id.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.confirmation_number,
                                color: color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  x['stationName']?.toString() ?? 'CNG Station',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Token $tokenLabel',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: color,
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
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_2,
                                size: 34, color: AppColors.text),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Booking reference',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SelectableText(
                                    d.id,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (x['position'] != null ||
                          x['estimatedWaitMinutes'] != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (x['position'] != null)
                              _infoPill(Icons.people_outline,
                                  'Queue position: ${x['position']}'),
                            if (x['estimatedWaitMinutes'] != null)
                              _infoPill(Icons.access_time,
                                  'Estimated wait: ${x['estimatedWaitMinutes']} min'),
                          ],
                        ),
                      ],
                      if (canCancel) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _cancel(context, d.id),
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('Cancel token'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                            ),
                          ),
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

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.green),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel token?'),
        content: const Text('Waiting token cancel करायचा आहे का?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep token'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel token'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await FirestoreService().cancelMyToken(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token cancelled.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not cancel token: $e')),
        );
      }
    }
  }
}

class _EmptyTokens extends StatelessWidget {
  const _EmptyTokens();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 42,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tokens yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Stations tab मधून token book करा.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
