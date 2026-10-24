import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM permission/token registration. Sending trusted notifications must happen
/// from a trusted backend; never send FCM using a server key from the app.
class NotificationService {
  NotificationService({FirebaseMessaging? messaging, FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<String?> initializeAndRegister() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return null;
    await _db.collection('users').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'notificationUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _messaging.onTokenRefresh.listen((freshToken) async {
      final current = _auth.currentUser;
      if (current == null) return;
      await _db.collection('users').doc(current.uid).set({
        'fcmTokens': FieldValue.arrayUnion([freshToken]),
        'notificationUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    return token;
  }

  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;
}
