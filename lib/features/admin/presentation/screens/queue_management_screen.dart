import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QueueManagementScreen extends StatelessWidget {
  const QueueManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Queue management')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('tokens')
              .where('stationOwnerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .orderBy('createdAt', descending: true)
              .limit(100)
              .snapshots(),
          builder: (context, s) {
            if (s.hasError)
              return const Center(child: Text('Could not load queue.'));
            if (!s.hasData)
              return const Center(child: CircularProgressIndicator());
            if (s.data!.docs.isEmpty)
              return const Center(child: Text('No tokens found.'));
            return ListView(
                padding: const EdgeInsets.all(12),
                children: s.data!.docs.map((d) {
                  final x = d.data();
                  return Card(
                      child: ListTile(
                          title: Text('Token ${x['tokenNumber'] ?? d.id}'),
                          subtitle: Text(
                              'Customer: ${x['customerId'] ?? '—'}\nStation: ${x['stationName'] ?? x['stationId'] ?? '—'}'),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                              initialValue: x['status']?.toString(),
                              onSelected: (v) => d.reference.update({
                                    'status': v,
                                    'updatedAt': FieldValue.serverTimestamp()
                                  }),
                              itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'waiting',
                                        child: Text('Waiting')),
                                    PopupMenuItem(
                                        value: 'serving',
                                        child: Text('Serving')),
                                    PopupMenuItem(
                                        value: 'completed',
                                        child: Text('Completed')),
                                    PopupMenuItem(
                                        value: 'cancelled',
                                        child: Text('Cancelled'))
                                  ],
                              child: Chip(
                                  label: Text(
                                      x['status']?.toString() ?? 'pending')))));
                }).toList());
          }));
}
