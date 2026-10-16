import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

class StationsScreen extends StatelessWidget {
  const StationsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('stations')
              .where('active', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const Center(
                  child: Text(
                      'Could not load stations. Check Firestore setup and rules.'));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty)
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.location_searching,
                            size: 52, color: AppColors.green),
                        SizedBox(height: 12),
                        Text('No stations added yet',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text(
                            'Stations appear here after an authorized pump owner adds them.',
                            textAlign: TextAlign.center)
                      ])));
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Text('CNG stations',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...docs.map((d) {
                final x = d.data();
                return Card(
                    color: Colors.white,
                    child: ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: AppColors.mint,
                            child: Icon(Icons.local_gas_station,
                                color: AppColors.green)),
                        title: Text(x['name']?.toString() ?? 'CNG Station',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${x['address'] ?? 'Address not provided'}\nStatus: ${x['availability'] ?? 'Unknown'} • Queue: ${x['queueCount'] ?? '—'}'),
                        isThreeLine: true,
                        trailing: Text(
                            x['pricePerKg'] == null
                                ? '—'
                                : '₹${x['pricePerKg']}/kg',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.green))));
              })
            ]);
          });
}
