import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/auth_repository.dart';

class OwnerPendingScreen extends StatelessWidget {
  const OwnerPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pump Owner Application'),
        actions: [
          IconButton(
              onPressed: () => AuthRepository().logout(),
              icon: const Icon(Icons.logout))
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: uid == null
                  ? const Stream.empty()
                  : FirebaseFirestore.instance
                      .collection('pumpOwnerApplications')
                      .doc(uid)
                      .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? <String, dynamic>{};
                final status = data['status']?.toString() ?? 'pending';
                final rejected = status == 'rejected';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                        rejected
                            ? Icons.cancel_outlined
                            : Icons.hourglass_top_rounded,
                        size: 72,
                        color: rejected ? Colors.red : Colors.teal),
                    const SizedBox(height: 20),
                    Text(
                        rejected
                            ? 'Application needs attention'
                            : 'Application submitted',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                        rejected
                            ? (data['reviewNote']?.toString().isNotEmpty == true
                                ? data['reviewNote'].toString()
                                : 'Your application was not approved. Contact support or submit a new application after correcting the details.')
                            : 'Your Pump Owner application is waiting for an administrator to review your details. You will be able to manage your station after approval.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    if (data['stationName'] != null)
                      Card(
                          child: ListTile(
                              leading: const Icon(Icons.local_gas_station),
                              title: Text(data['stationName'].toString()),
                              subtitle: Text(
                                  data['stationAddress']?.toString() ?? ''))),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                        onPressed: () => AuthRepository().logout(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out')),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
