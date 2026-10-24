import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            stream:
                FirebaseFirestore.instance.collection('stations').snapshots(),
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
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.red,
                        ),
                        onPressed: () => _deactivateStation(doc.id),
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
