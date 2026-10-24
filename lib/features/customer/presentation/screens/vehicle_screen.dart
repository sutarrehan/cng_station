import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_colors.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final TextEditingController _number = TextEditingController();
  final TextEditingController _model = TextEditingController();

  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _number.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in first.');
      return;
    }

    final vehicleNumber = _number.text.trim().toUpperCase();
    final vehicleModel = _model.text.trim();

    if (vehicleNumber.isEmpty) {
      _showMessage('Enter your vehicle registration number.');
      return;
    }

    if (_saving) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'vehicle': {
          'number': vehicleNumber,
          'model': vehicleModel,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() => _loaded = true);

      _showMessage('Vehicle details saved successfully.');
    } on FirebaseException catch (error) {
      if (!mounted) return;

      if (error.code == 'permission-denied') {
        _showMessage(
          'Permission denied. Update Firestore Rules to allow '
          'the vehicle field on your own user profile.',
        );
      } else if (error.code == 'not-found') {
        _showMessage(
          'User profile not found. Please complete registration first.',
        );
      } else {
        _showMessage(
          'Could not save vehicle: ${error.message ?? error.code}',
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not save vehicle details: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.green),
      filled: true,
      fillColor: AppColors.background,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.green, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please sign in to manage your vehicle.'),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Could not load vehicle details: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final document = snapshot.data!;

        if (!document.exists) {
          return const Center(
            child: Text(
              'User profile not found. Please complete registration.',
              textAlign: TextAlign.center,
            ),
          );
        }

        // Load saved values once; do not overwrite user edits
        // every time Firestore sends a new snapshot.
        if (!_loaded) {
          final data = document.data();
          final vehicle = data?['vehicle'];

          if (vehicle is Map) {
            _number.text = vehicle['number']?.toString() ?? '';
            _model.text = vehicle['model']?.toString() ?? '';
          }

          _loaded = true;
        }

        return Container(
          color: AppColors.background,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  const Text(
                    'My Vehicle',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Manage your vehicle details for future refueling '
                    'history and mileage tracking.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
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
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.directions_car_outlined,
                                color: AppColors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Vehicle details',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _number,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            label: 'Vehicle Registration Number',
                            hint: 'e.g. MH12AB1234',
                            icon: Icons.directions_car_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _model,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_saving) _save();
                          },
                          decoration: _decoration(
                            label: 'Vehicle Make / Model',
                            hint: 'e.g. Kia Carens',
                            icon: Icons.commute_outlined,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_saving ? 'Saving...' : 'Save Vehicle'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.green, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This vehicle is used when you book a queue token '
                            'at a station.',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
