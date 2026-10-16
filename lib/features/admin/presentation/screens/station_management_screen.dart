import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/constants/app_colors.dart';

class StationManagementScreen extends StatefulWidget {
  const StationManagementScreen({super.key});

  @override
  State<StationManagementScreen> createState() =>
      _StationManagementScreenState();
}

class _StationManagementScreenState extends State<StationManagementScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _queue = TextEditingController();

  String _availability = 'available';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _price.dispose();
    _queue.dispose();
    super.dispose();
  }

  Future<void> _addStation() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter station name and address.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('stations').add({
        'name': _name.text.trim(),
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
        'address': _address.text.trim(),
        'pricePerKg': double.tryParse(_price.text),
        'queueCount': int.tryParse(_queue.text) ?? 0,
        'availability': _availability,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _name.clear();
      _address.clear();
      _price.clear();
      _queue.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Station added successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add station: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _updateAvailability(String id, String value) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final userDoc = uid == null ? null : await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc?.data()?['role'] == 'admin') {
        await FirebaseFunctions.instance.httpsCallable('setStationAvailability').call({'stationId': id, 'availability': value});
      } else {
        await FirebaseFirestore.instance.collection('stations').doc(id).update({'availability': value, 'updatedAt': FieldValue.serverTimestamp()});
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update availability: $error')));
    }
  }

  Future<void> _editStation(String id, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['name']?.toString() ?? '');
    final addressController = TextEditingController(text: data['address']?.toString() ?? '');
    final priceController = TextEditingController(text: data['pricePerKg']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit station details'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Station name'), validator: (v) => v == null || v.trim().length < 2 ? 'Enter station name' : null),
            TextFormField(controller: addressController, decoration: const InputDecoration(labelText: 'Address'), validator: (v) => v == null || v.trim().length < 5 ? 'Enter full address' : null),
            TextFormField(controller: priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price per kg (₹)'), validator: (v) { if (v == null || v.trim().isEmpty) return null; final n = double.tryParse(v); return n == null || n < 0 ? 'Enter a valid price' : null; }),
          ])),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('Save'))],
      ),
    );
    if (save != true || !mounted) { nameController.dispose(); addressController.dispose(); priceController.dispose(); return; }
    try {
      await FirebaseFirestore.instance.collection('stations').doc(id).update({
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'pricePerKg': priceController.text.trim().isEmpty ? null : double.parse(priceController.text.trim()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Station details updated.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update station: $error')));
    } finally {
      nameController.dispose(); addressController.dispose(); priceController.dispose();
    }
  }

  Future<void> _deactivateStation(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate station?'),
        content: const Text(
          'The station will no longer be shown as active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('stations')
          .doc(id)
          .update({'active': false});
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not deactivate station: $error')),
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _stationStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance.collection('stations').where('ownerId', isEqualTo: uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Station Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Add a Station',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Station name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Full address'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price per kg (₹)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _queue,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Reported queue count',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _availability,
            decoration: const InputDecoration(
              labelText: 'Reported availability',
            ),
            items: const [
              DropdownMenuItem(
                value: 'available',
                child: Text('Available'),
              ),
              DropdownMenuItem(
                value: 'limited',
                child: Text('Limited'),
              ),
              DropdownMenuItem(
                value: 'unavailable',
                child: Text('Unavailable'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _availability = value ?? 'available';
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _addStation,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Add Station'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Existing Stations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stationStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Could not load stations.');
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No stations added yet.'),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data();

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.local_gas_station,
                        color: AppColors.green,
                      ),
                      title: Text(data['name']?.toString() ?? 'Station'),
                      subtitle: Text(
                        '${data['address'] ?? ''}\n'
                        'Status: ${data['availability'] ?? 'Unknown'}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _editStation(doc.id, data);
                          else if (value == 'deactivate') _deactivateStation(doc.id);
                          else _updateAvailability(doc.id, value);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit station details')),
                          PopupMenuItem(value: 'available', child: Text('Mark available')),
                          PopupMenuItem(value: 'limited', child: Text('Mark limited')),
                          PopupMenuItem(value: 'unavailable', child: Text('Mark unavailable')),
                          PopupMenuItem(value: 'deactivate', child: Text('Deactivate station')),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
