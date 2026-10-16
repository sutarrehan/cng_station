const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
initializeApp();
const db = getFirestore();

async function requireAdmin(uid) {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  const snap = await db.collection('users').doc(uid).get();
  if (!snap.exists || snap.data().role !== 'admin') {
    throw new HttpsError('permission-denied', 'Authorized pump owner only.');
  }
}

exports.createToken = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  const { stationId } = request.data || {};
  if (typeof stationId !== 'string' || !stationId.trim()) {
    throw new HttpsError('invalid-argument', 'stationId is required.');
  }
  const stationRef = db.collection('stations').doc(stationId);
  const tokenRef = db.collection('tokens').doc();
  return db.runTransaction(async (tx) => {
    const station = await tx.get(stationRef);
    if (!station.exists || station.data().active !== true) {
      throw new HttpsError('not-found', 'Station is unavailable.');
    }
    if (station.data().availability === 'unavailable') {
      throw new HttpsError('failed-precondition', 'This station is currently unavailable.');
    }
    const waiting = await tx.get(db.collection('tokens')
      .where('stationId', '==', stationId).where('status', '==', 'waiting'));
    const number = (station.data().lastTokenNumber || 0) + 1;
    const stationData = station.data();
    tx.update(stationRef, { lastTokenNumber: number, queueCount: waiting.size + 1 });
    tx.set(tokenRef, {
      customerId: request.auth.uid, stationId, stationName: stationData.name || 'CNG Station',
      tokenNumber: number, position: waiting.size + 1, status: 'waiting',
      createdAt: FieldValue.serverTimestamp()
    });
    return { tokenId: tokenRef.id, tokenNumber: number, position: waiting.size + 1 };
  });
});

exports.auditNewComplaint = onDocumentCreated('complaints/{complaintId}', async (event) => {
  const complaint = event.data?.data();
  if (!complaint) return;
  await db.collection('auditLogs').add({
    type: 'complaint_created', complaintId: event.params.complaintId,
    customerId: complaint.customerId || null, createdAt: FieldValue.serverTimestamp()
  });
});

exports.setStationAvailability = onCall(async (request) => {
  await requireAdmin(request.auth?.uid);
  const { stationId, availability, pricePerKg, queueCount } = request.data || {};
  if (!stationId || !['available', 'limited', 'unavailable'].includes(availability)) {
    throw new HttpsError('invalid-argument', 'Valid stationId and availability are required.');
  }
  const patch = { availability, updatedAt: FieldValue.serverTimestamp() };
  if (pricePerKg !== undefined) {
    if (typeof pricePerKg !== 'number' || pricePerKg < 0) throw new HttpsError('invalid-argument', 'Invalid price.');
    patch.pricePerKg = pricePerKg;
  }
  if (queueCount !== undefined) {
    if (!Number.isInteger(queueCount) || queueCount < 0) throw new HttpsError('invalid-argument', 'Invalid queue count.');
    patch.queueCount = queueCount;
  }
  await db.collection('stations').doc(stationId).update(patch);
  return { ok: true };
});
