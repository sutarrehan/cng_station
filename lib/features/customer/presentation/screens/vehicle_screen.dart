import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _number = TextEditingController();
  final _model = TextEditingController();

  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _number.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first.')),
      );
      return;
    }

    if (_number.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your vehicle registration number.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'vehicle': {
            'number': _number.text.trim().toUpperCase(),
            'model': _model.text.trim(),
          },
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle details saved successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save vehicle details: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(
        child: Text('Please sign in to manage your vehicle.'),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!_loaded && snapshot.hasData) {
          final data = snapshot.data?.data();
          final vehicle = data?['vehicle'];

          if (vehicle is Map) {
            _number.text = vehicle['number']?.toString() ?? '';
            _model.text = vehicle['model']?.toString() ?? '';
          }

          _loaded = true;
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'My Vehicle',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your vehicle details for future refueling '
              'history and mileage tracking.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _number,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Vehicle Registration Number',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _model,
              decoration: const InputDecoration(
                labelText: 'Vehicle Make / Model',
                prefixIcon: Icon(Icons.commute_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Vehicle'),
              ),
            ),
          ],
        );
      },
    );
  }
}
