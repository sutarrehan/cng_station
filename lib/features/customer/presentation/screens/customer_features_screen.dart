import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';

/// Additional customer tools. Existing dashboard/station layouts are preserved;
/// this screen is opened from the existing dashboard's Quick Actions.
class CustomerFeaturesScreen extends StatelessWidget {
  const CustomerFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please sign in first.'));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Customer Services')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(context, 'Account & Vehicles', [
                _item(
                    context,
                    Icons.verified_user_outlined,
                    'Email verification',
                    'Verify your email address',
                    () => _verifyEmail(context)),
                _item(
                    context,
                    Icons.directions_car_outlined,
                    'Manage vehicles',
                    'Add, edit, delete and choose primary',
                    () => _open(context, const _VehiclesPage())),
                _item(
                    context,
                    Icons.person_outline,
                    'Profile & account',
                    'Edit name and phone number',
                    () => _open(context, const _ProfilePage())),
              ]),
              _section(context, 'Booking & History', [
                _item(
                    context,
                    Icons.qr_code_2,
                    'My QR tokens',
                    'View booking QR and queue status',
                    () => _open(context, const _TokenHistoryPage())),
                _item(
                    context,
                    Icons.local_gas_station_outlined,
                    'Refueling history',
                    'Review recorded refuels',
                    () => _open(
                        context,
                        const _DataListPage(
                            title: 'Refueling History',
                            collection: 'refuelingLogs'))),
                _item(
                    context,
                    Icons.speed_outlined,
                    'Mileage tracking',
                    'Record odometer, kg and cost',
                    () => _open(context, const _MileagePage())),
                _item(
                    context,
                    Icons.notifications_active_outlined,
                    'Fuel reminders',
                    'Create and manage reminders',
                    () => _open(context, const _RemindersPage())),
              ]),
              _section(context, 'Station & Support', [
                _item(
                    context,
                    Icons.local_offer_outlined,
                    'Offers & coupons',
                    'See active offers and available coupons',
                    () => _open(
                        context,
                        const _DataListPage(
                            title: 'Offers & Coupons',
                            collection: 'offers',
                            publicRead: true))),
                _item(
                    context,
                    Icons.report_problem_outlined,
                    'Complaints',
                    'Submit a complaint and track its status',
                    () => _open(context, const _ComplaintsPage())),
                _item(
                    context,
                    Icons.star_outline,
                    'Station ratings & reviews',
                    'Rate a station and leave feedback',
                    () => _open(context, const _ReviewsPage())),
                _item(
                    context,
                    Icons.route_outlined,
                    'Destination discovery',
                    'Search CNG stations near a destination',
                    () => _open(context, const _DestinationPage())),
                _item(
                    context,
                    Icons.compare_arrows,
                    'Price & queue comparison',
                    'Compare active stations',
                    () => _open(context, const _StationComparePage())),
                _item(
                    context,
                    Icons.schedule,
                    'Best time to refuel',
                    'Estimate a quieter time from available queue data',
                    () => _open(context, const _BestTimePage())),
              ]),
              const SizedBox(height: 12),
              const Text(
                'Payments are only enabled after a trusted backend can create Razorpay orders and verify signatures. QR codes identify a token; station-side validation is still required.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _section(
      BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.border)),
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, color: AppColors.border),
              children[i],
            ],
          ]),
        ),
      ]),
    );
  }

  static Widget _item(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
          backgroundColor: const Color(0xFFE4F5EB),
          child: Icon(icon, color: AppColors.green)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  static Future<void> _verifyEmail(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Capture the messenger before awaiting; don't use BuildContext after an async gap.
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (user.emailVerified) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Your email is already verified.')),
        );
      } else {
        await user.sendEmailVerification();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
                'Verification email sent. Check your inbox and refresh your sign-in.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(e.message ?? 'Could not send verification email.')),
      );
    }
  }

  static void message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _PageShell extends StatelessWidget {
  const _PageShell({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(title)),
        body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: child,
            )),
      );
}

class _VehiclesPage extends StatefulWidget {
  const _VehiclesPage();
  @override
  State<_VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<_VehiclesPage> {
  final _db = FirebaseFirestore.instance;
  final _number = TextEditingController();
  final _model = TextEditingController();
  bool _saving = false;
  String? _editing;
  @override
  void dispose() {
    _number.dispose();
    _model.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _save() async {
    final number = _number.text.trim().toUpperCase();
    if (number.isEmpty) return;
    setState(() => _saving = true);
    try {
      final ref = _db.collection('vehicles');
      if (_editing == null) {
        final existing = await ref.where('customerId', isEqualTo: _uid).get();
        await ref.add({
          'customerId': _uid,
          'number': number,
          'model': _model.text.trim(),
          'isPrimary': existing.docs.isEmpty,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.doc(_editing).update({
          'number': number,
          'model': _model.text.trim(),
          'updatedAt': FieldValue.serverTimestamp()
        });
      }
      _number.clear();
      _model.clear();
      if (mounted) setState(() => _editing = null);
    } catch (e) {
      if (mounted) _toast('Could not save vehicle: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  @override
  Widget build(BuildContext context) => _PageShell(
      title: 'Manage Vehicles',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
            controller: _number,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                labelText: 'Vehicle registration number',
                border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(
            controller: _model,
            decoration: const InputDecoration(
                labelText: 'Vehicle model (optional)',
                border: OutlineInputBorder())),
        const SizedBox(height: 10),
        FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_editing == null ? 'Add vehicle' : 'Save changes')),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db
              .collection('vehicles')
              .where('customerId', isEqualTo: _uid)
              .snapshots(),
          builder: (context, s) {
            if (s.hasError) {
              return const Text(
                  'Could not load vehicles. Check Firestore Rules.');
            }
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.data!.docs.isEmpty) {
              return const Text('No saved vehicles yet.');
            }
            return Column(
                children: s.data!.docs.map((d) {
              final x = d.data();
              return Card(
                  child: ListTile(
                leading: Icon(
                    x['isPrimary'] == true ? Icons.star : Icons.directions_car,
                    color: AppColors.green),
                title: Text('${x['number'] ?? 'Vehicle'}'),
                subtitle: Text(
                    '${x['model'] ?? ''}${x['isPrimary'] == true ? ' • Primary' : ''}'),
                onTap: () {
                  _editing = d.id;
                  _number.text = '${x['number'] ?? ''}';
                  _model.text = '${x['model'] ?? ''}';
                  setState(() {});
                },
                trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      try {
                        if (v == 'primary') {
                          final batch = _db.batch();
                          for (final doc in s.data!.docs) {
                            batch.update(doc.reference, {
                              'isPrimary': doc.id == d.id,
                              'updatedAt': FieldValue.serverTimestamp()
                            });
                          }
                          await batch.commit();
                        } else if (v == 'delete') {
                          await d.reference.delete();
                        }
                      } catch (e) {
                        _toast('Action failed: $e');
                      }
                    },
                    itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'primary', child: Text('Set as primary')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ]),
              ));
            }).toList());
          },
        ),
      ]));
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage();
  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _PageShell(
          title: 'Profile', child: Center(child: Text('Please sign in.')));
    }
    return _PageShell(
        title: 'Profile & Account',
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, s) {
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = s.data!.data() ?? {};
            if (!_loaded) {
              _name.text = '${data['name'] ?? user.displayName ?? ''}';
              _phone.text = '${data['phone'] ?? ''}';
              _loaded = true;
            }
            return ListView(padding: const EdgeInsets.all(16), children: [
              ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(user.email ?? 'No email'),
                  subtitle: Text(user.emailVerified
                      ? 'Email verified'
                      : 'Email not verified')),
              TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Phone', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({
                              'name': _name.text.trim(),
                              'phone': _phone.text.trim(),
                              'updatedAt': FieldValue.serverTimestamp()
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Profile updated.')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Update failed: $e')));
                            }
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  child: const Text('Save profile')),
            ]);
          },
        ));
  }
}

class _TokenHistoryPage extends StatelessWidget {
  const _TokenHistoryPage();
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _PageShell(
          title: 'My QR Tokens', child: Center(child: Text('Please sign in.')));
    }
    return _PageShell(
        title: 'My QR Tokens',
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('tokens')
              .where('customerId', isEqualTo: uid)
              .snapshots(),
          builder: (context, s) {
            if (s.hasError) {
              return const Center(
                  child:
                      Text('Could not load bookings. Check Firestore Rules.'));
            }
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = s.data!.docs.toList()
              ..sort((a, b) => _time(b.data()['createdAt'])
                  .compareTo(_time(a.data()['createdAt'])));
            if (docs.isEmpty) {
              return const Center(child: Text('No bookings yet.'));
            }
            return ListView(
                padding: const EdgeInsets.all(16),
                children: docs.map((d) {
                  final x = d.data();
                  final status = '${x['status'] ?? 'waiting'}';
                  final token = '${x['tokenNumber'] ?? d.id}';
                  return Card(
                      child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${x['stationName'] ?? 'CNG Station'}',
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold)),
                                Text('Token $token • ${status.toUpperCase()}'),
                                Text(
                                    'Queue position: ${x['queuePosition'] ?? 'Pending station update'}'),
                                Text(
                                    'Estimated wait: ${x['estimatedWaitMinutes'] ?? 'Pending'} min'),
                                Center(
                                    child: QrImageView(
                                        data:
                                            'CNGPULSE|${d.id}|${x['stationId'] ?? ''}|$token',
                                        size: 180,
                                        backgroundColor: Colors.white)),
                                Text('QR reference: ${d.id}',
                                    style: const TextStyle(fontSize: 11)),
                                if (status == 'waiting')
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                          onPressed: () async {
                                            try {
                                              await d.reference.update({
                                                'status': 'cancelled',
                                                'updatedAt':
                                                    FieldValue.serverTimestamp()
                                              });
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            'Cancel failed: $e')));
                                              }
                                            }
                                          },
                                          icon:
                                              const Icon(Icons.cancel_outlined),
                                          label: const Text('Cancel token'))),
                              ])));
                }).toList());
          },
        ));
  }
}

int _time(dynamic value) =>
    value is Timestamp ? value.millisecondsSinceEpoch : 0;

class _MileagePage extends StatefulWidget {
  const _MileagePage();
  @override
  State<_MileagePage> createState() => _MileagePageState();
}

class _MileagePageState extends State<_MileagePage> {
  final _odo = TextEditingController();
  final _kg = TextEditingController();
  final _cost = TextEditingController();
  final _station = TextEditingController();
  @override
  void dispose() {
    _odo.dispose();
    _kg.dispose();
    _cost.dispose();
    _station.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _PageShell(
          title: 'Mileage', child: Center(child: Text('Please sign in.')));
    }
    final db = FirebaseFirestore.instance;
    return _PageShell(
        title: 'Mileage & Refueling',
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: _odo,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Odometer reading (km)',
                  border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
              controller: _kg,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'CNG filled (kg)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Total cost (₹)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
              controller: _station,
              decoration: const InputDecoration(
                  labelText: 'Station name (optional)',
                  border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: () async {
                final odo = double.tryParse(_odo.text);
                final kg = double.tryParse(_kg.text);
                final cost = double.tryParse(_cost.text);
                if (odo == null ||
                    kg == null ||
                    kg <= 0 ||
                    cost == null ||
                    cost < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Enter valid odometer, kg and cost.')));
                  return;
                }
                try {
                  final prior = await db
                      .collection('refuelingLogs')
                      .where('customerId', isEqualTo: uid)
                      .get();
                  double? efficiency;
                  if (prior.docs.isNotEmpty) {
                    final sorted = prior.docs.toList()
                      ..sort((a, b) => _time(b.data()['createdAt'])
                          .compareTo(_time(a.data()['createdAt'])));
                    final last = sorted.first.data();
                    final lastOdo = (last['odometerKm'] as num?)?.toDouble();
                    final lastKg = (last['kg'] as num?)?.toDouble();
                    if (lastOdo != null &&
                        odo > lastOdo &&
                        lastKg != null &&
                        lastKg > 0) {
                      efficiency = (odo - lastOdo) / lastKg;
                    }
                  }
                  await db.collection('refuelingLogs').add({
                    'customerId': uid,
                    'odometerKm': odo,
                    'kg': kg,
                    'cost': cost,
                    'stationName': _station.text.trim(),
                    'kmPerKg': efficiency,
                    'createdAt': FieldValue.serverTimestamp()
                  });
                  _odo.clear();
                  _kg.clear();
                  _cost.clear();
                  _station.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(efficiency == null
                            ? 'Refueling saved. Add the next odometer reading to calculate km/kg.'
                            : 'Saved. Latest efficiency: ${efficiency.toStringAsFixed(2)} km/kg')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Save failed: $e')));
                  }
                }
              },
              child: const Text('Save refueling record')),
          const SizedBox(height: 18),
          const Text('Your recent refueling records',
              style: TextStyle(fontWeight: FontWeight.bold)),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('refuelingLogs')
                  .where('customerId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = s.data!.docs.toList()
                  ..sort((a, b) => _time(b.data()['createdAt'])
                      .compareTo(_time(a.data()['createdAt'])));
                return Column(
                    children: docs.take(10).map((d) {
                  final x = d.data();
                  return ListTile(
                      title: Text('${x['kg']} kg • ₹${x['cost']}'),
                      subtitle: Text(
                          'Odometer ${x['odometerKm']} km • ${x['kmPerKg'] ?? 'Efficiency pending'} km/kg'));
                }).toList());
              }),
        ]));
  }
}

class _RemindersPage extends StatefulWidget {
  const _RemindersPage();
  @override
  State<_RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<_RemindersPage> {
  final _title = TextEditingController(text: 'CNG refill');
  final _odo = TextEditingController();
  @override
  void dispose() {
    _title.dispose();
    _odo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _PageShell(
          title: 'Reminders', child: Center(child: Text('Please sign in.')));
    }
    final db = FirebaseFirestore.instance;
    return _PageShell(
        title: 'Fuel Reminders',
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Reminder title', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
              controller: _odo,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Remind at odometer km (optional)',
                  border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: () async {
                try {
                  await db.collection('fuelReminders').add({
                    'customerId': uid,
                    'title': _title.text.trim().isEmpty
                        ? 'CNG refill'
                        : _title.text.trim(),
                    'targetOdometerKm': double.tryParse(_odo.text),
                    'enabled': true,
                    'createdAt': FieldValue.serverTimestamp()
                  });
                  _odo.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Reminder saved. Automatic scheduled push requires a backend.')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Save failed: $e')));
                  }
                }
              },
              child: const Text('Save reminder')),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('fuelReminders')
                  .where('customerId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                    children: s.data!.docs.map((d) {
                  final x = d.data();
                  return SwitchListTile(
                      title: Text('${x['title'] ?? 'Fuel reminder'}'),
                      subtitle: Text(
                          'Target odometer: ${x['targetOdometerKm'] ?? 'Not set'}'),
                      value: x['enabled'] == true,
                      onChanged: (v) => d.reference.update({'enabled': v}));
                }).toList());
              }),
        ]));
  }
}

class _ComplaintsPage extends StatefulWidget {
  const _ComplaintsPage();

  @override
  State<_ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<_ComplaintsPage> {
  final TextEditingController _description = TextEditingController();
  String _category = 'Service';
  bool _submitting = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit(String uid) async {
    final description = _description.text.trim();

    if (description.length < 8) {
      _showMessage('Please provide at least 8 characters.');
      return;
    }

    setState(() => _submitting = true);

    try {
      await FirebaseFirestore.instance.collection('complaints').add({
        'customerId': uid,
        'category': _category,
        'description': description,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _description.clear();
      _showMessage('Complaint submitted.');
    } catch (error) {
      _showMessage('Submit failed: $error');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const _PageShell(
        title: 'Complaints',
        child: Center(child: Text('Please sign in.')),
      );
    }

    final complaintsStream = FirebaseFirestore.instance
        .collection('complaints')
        .where('customerId', isEqualTo: uid)
        .snapshots();

    return _PageShell(
      title: 'Complaints',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: const <String>[
              'Service',
              'Payment',
              'Queue',
              'Station',
              'Other',
            ].map<DropdownMenuItem<String>>((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _category = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Describe your complaint',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : () => _submit(uid),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Submit complaint'),
            ),
          ),
          const Divider(height: 28),
          const Text(
            'My complaints',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: complaintsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Could not load complaints. Check Firestore Rules.',
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final docs = snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('No complaints submitted yet.'),
                  ),
                );
              }

              final List<Widget> complaintTiles = docs.map<Widget>((document) {
                final data = document.data();

                final category = (data['category'] ?? 'Complaint').toString();

                final description = (data['description'] ?? '').toString();

                final status = (data['status'] ?? 'open').toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.report_outlined),
                    title: Text(category),
                    subtitle: Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 90),
                      child: Text(
                        status.toUpperCase(),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: complaintTiles,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReviewsPage extends StatefulWidget {
  const _ReviewsPage();
  @override
  State<_ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<_ReviewsPage> {
  final _review = TextEditingController();
  int _rating = 5;
  String? _station;
  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _PageShell(
          title: 'Reviews', child: Center(child: Text('Please sign in.')));
    }
    final db = FirebaseFirestore.instance;
    return _PageShell(
        title: 'Station Ratings & Reviews',
        child: ListView(padding: const EdgeInsets.all(16), children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('stations')
                  .where('active', isEqualTo: true)
                  .snapshots(),
              builder: (context, s) {
                if (!s.hasData) return const LinearProgressIndicator();
                final docs = s.data!.docs;
                return DropdownButtonFormField<String>(
                    initialValue: _station,
                    decoration: const InputDecoration(
                        labelText: 'Station', border: OutlineInputBorder()),
                    items: docs
                        .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text('${d.data()['name'] ?? 'Station'}',
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _station = v));
              }),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Rating: '),
            for (int i = 1; i <= 5; i++)
              IconButton(
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(i <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber))
          ]),
          TextField(
              controller: _review,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Review (optional)',
                  border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: () async {
                if (_station == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Choose a station.')));
                  return;
                }
                try {
                  await db.collection('reviews').add({
                    'customerId': uid,
                    'stationId': _station,
                    'rating': _rating,
                    'review': _review.text.trim(),
                    'createdAt': FieldValue.serverTimestamp()
                  });
                  _review.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Review submitted.')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Review failed: $e')));
                  }
                }
              },
              child: const Text('Submit review')),
        ]));
  }
}

class _DestinationPage extends StatefulWidget {
  const _DestinationPage();
  @override
  State<_DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<_DestinationPage> {
  final _destination = TextEditingController();
  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _PageShell(
      title: 'Destination Discovery',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text(
            'Search for CNG stations around your destination using the free Google Maps web search. No embedded Maps API key is required.'),
        const SizedBox(height: 12),
        TextField(
            controller: _destination,
            decoration: const InputDecoration(
                labelText: 'Destination or city',
                border: OutlineInputBorder())),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: () async {
              final q = _destination.text.trim();
              if (q.isEmpty) return;
              final uri = Uri.https('www.google.com', '/maps/search/',
                  {'api': '1', 'query': 'CNG stations near $q'});
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Find CNG stations')),
      ]));
}

class _StationComparePage extends StatelessWidget {
  const _StationComparePage();
  @override
  Widget build(BuildContext context) => _PageShell(
      title: 'Station Comparison',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('stations')
              .where('active', isEqualTo: true)
              .snapshots(),
          builder: (context, s) {
            if (s.hasError) {
              return const Center(child: Text('Could not load stations.'));
            }
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = s.data!.docs.toList()
              ..sort((a, b) {
                final ap =
                    (a.data()['pricePerKg'] as num?)?.toDouble() ?? 999999;
                final bp =
                    (b.data()['pricePerKg'] as num?)?.toDouble() ?? 999999;
                return ap.compareTo(bp);
              });
            if (docs.isEmpty) {
              return const Center(child: Text('No active stations found.'));
            }
            return ListView(
                padding: const EdgeInsets.all(12),
                children: docs.map((d) {
                  final x = d.data();
                  return Card(
                      child: ListTile(
                          leading: const Icon(Icons.local_gas_station,
                              color: AppColors.green),
                          title: Text('${x['name'] ?? 'Station'}'),
                          subtitle: Text(
                              '${x['address'] ?? ''}\\nQueue: ${x['queueCount'] ?? 'N/A'} • Wait: ${x['estimatedWaitMinutes'] ?? 'N/A'} min'),
                          isThreeLine: true,
                          trailing: Text(
                              x['pricePerKg'] == null
                                  ? 'Price N/A'
                                  : '₹${x['pricePerKg']}/kg',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))));
                }).toList());
          }));
}

class _BestTimePage extends StatelessWidget {
  const _BestTimePage();
  @override
  Widget build(BuildContext context) => _PageShell(
      title: 'Best Time to Refuel',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('stations')
              .where('active', isEqualTo: true)
              .snapshots(),
          builder: (context, s) {
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = s.data!.docs.toList()
              ..sort((a, b) =>
                  ((a.data()['queueCount'] as num?)?.toInt() ?? 999999)
                      .compareTo(
                          (b.data()['queueCount'] as num?)?.toInt() ?? 999999));
            if (docs.isEmpty) {
              return const Center(child: Text('No queue data available.'));
            }
            final x = docs.first.data();
            return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule,
                          size: 54, color: AppColors.green),
                      const SizedBox(height: 12),
                      const Text('Current low-queue suggestion',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${x['name'] ?? 'Station'}',
                          style: const TextStyle(fontSize: 22)),
                      Text(
                          'Queue: ${x['queueCount'] ?? 'N/A'} • Estimated wait: ${x['estimatedWaitMinutes'] ?? 'N/A'} min'),
                      const SizedBox(height: 10),
                      const Text(
                          'This is a current-queue heuristic, not a trained AI forecast. Availability depends on station data.')
                    ]));
          }));
}

class _DataListPage extends StatelessWidget {
  const _DataListPage(
      {required this.title, required this.collection, this.publicRead = false});
  final String title;
  final String collection;
  final bool publicRead;
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection(collection);
    if (collection == 'refuelingLogs' && uid != null) {
      query = query.where('customerId', isEqualTo: uid);
    }
    if (collection == 'offers') query = query.where('active', isEqualTo: true);
    return _PageShell(
        title: title,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, s) {
              if (s.hasError) {
                return Center(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                            'Could not load $title. Check Firestore Rules.')));
              }
              if (!s.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (s.data!.docs.isEmpty) {
                return Center(
                    child: Text('No ${title.toLowerCase()} available yet.'));
              }
              return ListView(
                  padding: const EdgeInsets.all(12),
                  children: s.data!.docs.map((d) {
                    final x = d.data();
                    return Card(
                        child: ListTile(
                            title: Text(
                                '${x['title'] ?? x['stationName'] ?? x['category'] ?? 'Record'}'),
                            subtitle: Text(
                                '${x['description'] ?? x['details'] ?? x['odometerKm'] ?? ''}'),
                            trailing:
                                Text('${x['status'] ?? x['code'] ?? ''}')));
                  }).toList());
            }));
  }
}
