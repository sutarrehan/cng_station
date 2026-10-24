import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Typed Firestore gateway used by CNGPulse UI and repositories.
/// Authorization is enforced by firestore.rules; client checks are not
/// security boundaries.
class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in first.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _stations =>
      _db.collection('stations');

  CollectionReference<Map<String, dynamic>> get _tokens =>
      _db.collection('tokens');

  CollectionReference<Map<String, dynamic>> get _complaints =>
      _db.collection('complaints');

  Future<Map<String, dynamic>?> getMyProfile() async {
    final doc = await _users.doc(_uid).get();
    return doc.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMyProfile() {
    return _users.doc(_uid).snapshots();
  }

  Future<void> updateMyProfile({
    required String name,
    required String phone,
  }) async {
    final cleanName = name.trim();

    if (cleanName.length < 2) {
      throw ArgumentError('Enter a valid name.');
    }

    await _users.doc(_uid).update({
      'name': cleanName,
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchStations() {
    return _stations.orderBy('name').snapshots();
  }

  Future<String> createToken({
    required String stationId,
    String? vehicleId,
  }) async {
    if (stationId.trim().isEmpty) {
      throw ArgumentError('Choose a station.');
    }

    final uid = _uid;
    final stationRef = _stations.doc(stationId);
    final counterRef = _db.collection('stationCounters').doc(stationId);
    final tokenRef = _tokens.doc();

    await _db.runTransaction((transaction) async {
      // All reads occur before writes so Firestore can retry atomically on contention.
      final station = await transaction.get(stationRef);
      final counter = await transaction.get(counterRef);

      if (!station.exists) {
        throw StateError('This station is no longer available.');
      }

      final stationData = station.data() ?? <String, dynamic>{};
      if (stationData['active'] == false) {
        throw StateError('This station is currently unavailable.');
      }

      final previous = (counter.data()?['lastTokenNumber'] as num?)?.toInt() ?? 0;
      final tokenNumber = previous + 1;
      final queueCount = (stationData['queueCount'] as num?)?.toInt() ?? 0;
      final estimatedWait = (stationData['estimatedWaitMinutes'] as num?)?.toInt();

      transaction.set(counterRef, {
        'stationId': stationId,
        'lastTokenNumber': tokenNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(tokenRef, {
        'customerId': uid,
        'stationOwnerId': stationData['ownerId'],
        'stationName': stationData['name'],
        'stationId': stationId,
        'vehicleId': vehicleId,
        'tokenNumber': tokenNumber,
        'queuePosition': queueCount + 1,
        'estimatedWaitMinutes': estimatedWait,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return tokenRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyTokens() {
    return _tokens
        .where('customerId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> cancelMyToken(String tokenId) async {
    final ref = _tokens.doc(tokenId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);

      if (!snap.exists || snap.data()?['customerId'] != _uid) {
        throw StateError('Booking not found or access denied.');
      }

      final status = snap.data()?['status'];

      if (status != 'waiting') {
        throw StateError('Only waiting bookings can be cancelled.');
      }

      transaction.update(ref, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<String> submitComplaint({
    required String category,
    required String description,
    String? stationId,
    String? imageUrl,
  }) async {
    final cleanDescription = description.trim();

    if (cleanDescription.length < 8) {
      throw ArgumentError(
        'Please describe the issue in more detail.',
      );
    }

    final ref = await _complaints.add({
      'customerId': _uid,
      'category': category,
      'description': cleanDescription,
      'stationId': stationId,
      'imageUrl': imageUrl,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyComplaints() {
    return _complaints
        .where('customerId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
