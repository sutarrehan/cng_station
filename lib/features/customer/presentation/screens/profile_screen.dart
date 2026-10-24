import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firestore_service.dart';

/// Customer profile backed by the signed-in user's Firestore profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _service = FirestoreService();
  bool _saving = false;
  String? _loadedUid;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.updateMyProfile(name: _name.text, phone: _phone.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _loadProfile(Map<String, dynamic> data, String uid) {
    if (_loadedUid == uid) return;
    _loadedUid = uid;
    _name.text = (data['name'] ?? '').toString();
    _phone.text = (data['phone'] ?? '').toString();
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view your profile.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _service.watchMyProfile(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load your profile.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data?.data();
        if (data == null) {
          return const Center(child: Text('Profile details are unavailable.'));
        }
        _loadProfile(data, user.uid);

        final displayName = (data['name'] ?? 'CNGPulse User').toString();
        final initial = displayName.trim().isEmpty
            ? 'C'
            : displayName.trim().substring(0, 1).toUpperCase();
        final status = (data['accountStatus'] ?? 'unknown').toString();

        return Container(
          color: AppColors.background,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  // Profile header card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 26, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.green, AppColors.darkGreen],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33075B43),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0x66FFFFFF),
                              width: 3,
                            ),
                          ),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xE6FFFFFF)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Personal details card
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
                        const Text(
                          'Personal details',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                decoration: _decoration(
                                    'Full name', Icons.person_outline),
                                validator: (value) =>
                                    value == null || value.trim().length < 2
                                        ? 'Enter your full name'
                                        : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                decoration: _decoration(
                                    'Mobile number', Icons.phone_outlined),
                                validator: (value) {
                                  final phone = (value ?? '')
                                      .replaceAll(RegExp(r'[\s-]'), '');
                                  if (phone.isNotEmpty &&
                                      !RegExp(r'^\+?[0-9]{10,13}$')
                                          .hasMatch(phone)) {
                                    return 'Enter a valid mobile number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: _saving ? null : _save,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.green,
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
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                      _saving ? 'Saving...' : 'Save changes'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account status card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.verified_user_outlined,
                              color: AppColors.green),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Account status',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
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
