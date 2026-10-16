import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class PumpOwnerApplicationsScreen extends StatelessWidget {
  const PumpOwnerApplicationsScreen({super.key});

  Future<void> _review(BuildContext context, String uid, String decision) async {
    String? note;
    if (decision == 'reject') {
      note = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Reject application'),
            content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(labelText: 'Reason (optional)')),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Reject'))],
          );
        },
      );
      if (note == null) return;
    }
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('reviewPumpOwnerApplication');
      await callable.call(<String, dynamic>{'applicantUid': uid, 'decision': decision, if (note != null && note.isNotEmpty) 'reviewNote': note});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decision == 'approve' ? 'Pump Owner approved.' : 'Application rejected.')));
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Could not review application.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not review application. Check connection and Functions deployment.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pump Owner Applications')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('pumpOwnerApplications').where('status', isEqualTo: 'pending').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Could not load applications. Check Firestore rules and indexes.')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No pending Pump Owner applications.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final d = doc.data();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['stationName']?.toString() ?? 'Station application', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(d['name']?.toString() ?? 'Applicant'),
                    Text(d['email']?.toString() ?? ''),
                    Text(d['phone']?.toString() ?? ''),
                    const SizedBox(height: 8),
                    Text(d['stationAddress']?.toString() ?? 'No address supplied'),
                    const SizedBox(height: 14),
                    Wrap(spacing: 10, runSpacing: 8, children: [
                      FilledButton.icon(onPressed: () => _review(context, doc.id, 'approve'), icon: const Icon(Icons.verified_outlined), label: const Text('Approve')),
                      OutlinedButton.icon(onPressed: () => _review(context, doc.id, 'reject'), icon: const Icon(Icons.close), label: const Text('Reject')),
                    ]),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
