import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';

class TokensScreen extends StatelessWidget {
  const TokensScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please sign in.'));
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('tokens')
            .where('customerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, s) {
          if (s.hasError) {
            return const Center(child: Text('Could not load tokens.'));
          }
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = s.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.confirmation_number_outlined,
                          size: 50, color: AppColors.green),
                      SizedBox(height: 12),
                      Text('No tokens yet',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                          'Token booking will appear here once enabled by the station.')
                    ])));
          }
          return ListView(padding: const EdgeInsets.all(16), children: [
            const Text('My tokens',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ...docs.map((d) {
              final x = d.data();
              return Card(
                  color: Colors.white,
                  child: ListTile(
                      leading: const Icon(Icons.confirmation_number,
                          color: AppColors.green),
                      title: Text('Token ${x['tokenNumber'] ?? d.id}'),
                      subtitle: Text(
                          'Station: ${x['stationName'] ?? 'CNG Station'} • Queue position: ${x['position'] ?? '—'}'),
                      trailing: Text(x['status']?.toString() ?? 'Pending')));
            })
          ]);
        });
  }
}
