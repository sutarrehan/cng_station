import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';

const Color _kEmerald = Color(0xFF07865C);
const Color _kDarkGreen = Color(0xFF075B43);
const Color _kMint = Color(0xFFE4F5EB);
const Color _kBackground = Color(0xFFF6F9F7);
const Color _kTextMain = Color(0xFF172821);
const Color _kTextSecondary = Color(0xFF718078);

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

  String _filter = 'all';
  String _search = '';

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stationsStream;
  bool? _streamIsAdmin;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _profileStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    }
  }

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
        'pricePerKg': double.tryParse(_price.text.trim()),
        'queueCount': int.tryParse(_queue.text.trim()) ?? 0,
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
        const SnackBar(
          content: Text('Station added successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add station: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _updateAvailability(String id, String value) async {
    try {
      await FirebaseFirestore.instance.collection('stations').doc(id).update({
        'availability': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability updated.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update availability: $error'),
        ),
      );
    }
  }

  Future<void> _editStation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final nameController = TextEditingController(
      text: data['name']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: data['address']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: data['pricePerKg']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    try {
      final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Edit station details'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Station name',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 2) {
                        return 'Enter station name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 5) {
                        return 'Enter full address';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price per kg (₹)',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return null;
                      }

                      final number = double.tryParse(value.trim());

                      if (number == null || number < 0) {
                        return 'Enter a valid price';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (save != true || !mounted) return;

      await FirebaseFirestore.instance.collection('stations').doc(id).update({
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'pricePerKg': priceController.text.trim().isEmpty
            ? null
            : double.parse(priceController.text.trim()),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Station details updated.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update station: $error'),
        ),
      );
    } finally {
      nameController.dispose();
      addressController.dispose();
      priceController.dispose();
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
      await FirebaseFirestore.instance.collection('stations').doc(id).update({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Station deactivated.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not deactivate station: $error'),
        ),
      );
    }
  }

  Future<void> _activateStation(String id) async {
    try {
      await FirebaseFirestore.instance.collection('stations').doc(id).update({
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Station activated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not activate station: $error')),
      );
    }
  }

  /// Same behavior as before: admins see every station, owners see their own.
  /// The stream is cached so it is not re-created on every rebuild.
  Stream<QuerySnapshot<Map<String, dynamic>>> _stationStreamFor(bool isAdmin) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    if (_stationsStream == null || _streamIsAdmin != isAdmin) {
      _streamIsAdmin = isAdmin;
      final query = FirebaseFirestore.instance.collection('stations');
      _stationsStream = isAdmin
          ? query.snapshots()
          : query.where('ownerId', isEqualTo: uid).snapshots();
    }
    return _stationsStream!;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _kEmerald),
      filled: true,
      fillColor: _kBackground,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kEmerald, width: 1.5),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F075B43),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Station Management'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileStream,
        builder: (context, profileSnapshot) {
          if (_profileStream == null) {
            return const Center(child: Text('Please sign in again.'));
          }
          if (profileSnapshot.hasError) {
            return const Center(child: Text('Could not load your account.'));
          }
          if (!profileSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final isAdmin = profileSnapshot.data?.data()?['role'] == 'admin';

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _addForm(),
                  const SizedBox(height: 26),
                  Text(
                    isAdmin ? 'All Stations' : 'Existing Stations',
                    style: const TextStyle(
                      color: _kTextMain,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _stationsSection(isAdmin),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _addForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kMint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add_location_alt_outlined,
                    color: _kEmerald),
              ),
              const SizedBox(width: 12),
              const Text(
                'Add a Station',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kTextMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration('Station name', Icons.local_gas_station),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: _decoration('Full address', Icons.location_on_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: _decoration('Price per kg (₹)', Icons.currency_rupee),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _queue,
            keyboardType: TextInputType.number,
            decoration:
                _decoration('Reported queue count', Icons.people_outline),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _availability,
            decoration:
                _decoration('Reported availability', Icons.circle_outlined),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _addStation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kEmerald,
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
                  : const Icon(Icons.add),
              label: Text(_saving ? 'Adding...' : 'Add Station'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stationsSection(bool isAdmin) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stationStreamFor(isAdmin),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Could not load stations.');
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final documents = snapshot.data!.docs;

        if (documents.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: _kMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_gas_station,
                      color: _kEmerald, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No stations added yet.',
                  style: TextStyle(
                    color: _kTextMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }

        int activeCount =
            documents.where((d) => d.data()['active'] == true).length;
        int availCount(String v) =>
            documents.where((d) => d.data()['availability'] == v).length;

        final query = _search.trim().toLowerCase();
        final filtered = documents.where((d) {
          final x = d.data();
          final active = x['active'] == true;
          switch (_filter) {
            case 'active':
              if (!active) return false;
              break;
            case 'inactive':
              if (active) return false;
              break;
            case 'available':
            case 'limited':
            case 'unavailable':
              if (x['availability'] != _filter) return false;
              break;
          }
          if (query.isEmpty) return true;
          return '${x['name']} ${x['address']}'.toLowerCase().contains(query);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _summaryChip(
                    Icons.local_gas_station, '${documents.length} total'),
                _summaryChip(Icons.check_circle_outline, '$activeCount active'),
                _summaryChip(Icons.visibility_off_outlined,
                    '${documents.length - activeCount} inactive'),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search station or address',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _kEmerald, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', 'All'),
                  _filterChip('active', 'Active'),
                  _filterChip('inactive', 'Inactive'),
                  _filterChip(
                      'available', 'Available (${availCount('available')})'),
                  _filterChip('limited', 'Limited (${availCount('limited')})'),
                  _filterChip('unavailable',
                      'Unavailable (${availCount('unavailable')})'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No stations match your filters.',
                    style: TextStyle(color: _kTextSecondary),
                  ),
                ),
              )
            else
              ...filtered
                  .map((doc) => _stationCard(doc.id, doc.data(), isAdmin)),
          ],
        );
      },
    );
  }

  Widget _summaryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kMint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _kEmerald),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _kDarkGreen,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: _kMint,
        labelStyle: TextStyle(
          color: selected ? _kDarkGreen : _kTextSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        side: BorderSide(color: selected ? _kEmerald : AppColors.border),
        showCheckmark: false,
      ),
    );
  }

  Color _availabilityColor(String value) {
    switch (value) {
      case 'available':
        return Colors.green;
      case 'limited':
        return Colors.orange;
      case 'unavailable':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _stationCard(String id, Map<String, dynamic> data, bool isAdmin) {
    final active = data['active'] == true;
    final availability = (data['availability'] ?? 'unknown').toString();
    final price = data['pricePerKg'];
    final queue = data['queueCount'];
    final availColor = _availabilityColor(availability);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: active ? _kMint : const Color(0xFFEDEFEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.local_gas_station,
                  color: active ? _kEmerald : Colors.grey,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name']?.toString() ?? 'Station',
                      style: const TextStyle(
                        color: _kTextMain,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (data['address'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Station actions',
                onSelected: (value) {
                  if (value == 'edit') {
                    _editStation(id, data);
                  } else if (value == 'deactivate') {
                    _deactivateStation(id);
                  } else if (value == 'activate') {
                    _activateStation(id);
                  } else {
                    _updateAvailability(id, value);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit station details'),
                  ),
                  const PopupMenuItem(
                    value: 'available',
                    child: Text('Mark available'),
                  ),
                  const PopupMenuItem(
                    value: 'limited',
                    child: Text('Mark limited'),
                  ),
                  const PopupMenuItem(
                    value: 'unavailable',
                    child: Text('Mark unavailable'),
                  ),
                  if (active)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Text('Deactivate station'),
                    )
                  else
                    const PopupMenuItem(
                      value: 'activate',
                      child: Text('Activate station'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusPill(active ? 'ACTIVE' : 'INACTIVE',
                  active ? _kEmerald : Colors.grey),
              _statusPill(availability.toUpperCase(), availColor),
              if (price != null)
                _summaryChip(Icons.currency_rupee, '$price / kg'),
              if (queue != null)
                _summaryChip(Icons.people_outline, 'Queue $queue'),
            ],
          ),
          if (isAdmin && (data['ownerId'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Owner: ${data['ownerId']}',
              style: const TextStyle(color: _kTextSecondary, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      );
}
