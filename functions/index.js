const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
initializeApp();
const db = getFirestore();

async function requireAdmin(uid) {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  const snap = await db.collection('users').doc(uid).get();
  if (!snap.exists || snap.data().role !== 'admin' || snap.data().accountStatus !== 'active') {
    throw new HttpsError('permission-denied', 'Only an authorized administrator can perform this action.');
  }
}

exports.reviewPumpOwnerApplication = onCall(async (request) => {
  await requireAdmin(request.auth?.uid);
  const { applicantUid, decision, reviewNote } = request.data || {};
  if (typeof applicantUid !== 'string' || !applicantUid || !['approve', 'reject'].includes(decision)) {
    throw new HttpsError('invalid-argument', 'A valid applicantUid and decision are required.');
  }
  const appRef = db.collection('pumpOwnerApplications').doc(applicantUid);
  const userRef = db.collection('users').doc(applicantUid);
  await db.runTransaction(async (tx) => {
    const appSnap = await tx.get(appRef);
    const userSnap = await tx.get(userRef);
    if (!appSnap.exists || !userSnap.exists) throw new HttpsError('not-found', 'Application or user profile not found.');
    if (appSnap.data().status !== 'pending') throw new HttpsError('failed-precondition', 'This application has already been reviewed.');
    const now = FieldValue.serverTimestamp();
    if (decision === 'approve') {
      tx.update(userRef, { role: 'pumpOwner', accountStatus: 'active', ownerApplicationStatus: 'approved', updatedAt: now });
      tx.update(appRef, { status: 'approved', reviewedBy: request.auth.uid, reviewedAt: now, updatedAt: now });
    } else {
      tx.update(userRef, { ownerApplicationStatus: 'rejected', updatedAt: now });
      tx.update(appRef, { status: 'rejected', reviewNote: typeof reviewNote === 'string' ? reviewNote.slice(0, 500) : '', reviewedBy: request.auth.uid, reviewedAt: now, updatedAt: now });
    }
  });
  return { ok: true, applicantUid, status: decision === 'approve' ? 'approved' : 'rejected' };
});

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
      customerId: request.auth.uid, stationId, stationOwnerId: stationData.ownerId || null, stationName: stationData.name || 'CNG Station',
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
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  const { stationId, availability, pricePerKg, queueCount } = request.data || {};
  if (!stationId || !['available', 'limited', 'unavailable'].includes(availability)) {
    throw new HttpsError('invalid-argument', 'Valid stationId and availability are required.');
  }
  const stationRef = db.collection('stations').doc(stationId);
  const stationSnap = await stationRef.get();
  if (!stationSnap.exists) throw new HttpsError('not-found', 'Station not found.');
  const userSnap = await db.collection('users').doc(uid).get();
  const userData = userSnap.data() || {};
  const admin = userData.role === 'admin' && userData.accountStatus === 'active';
  const owner = userData.role === 'pumpOwner' && userData.accountStatus === 'active' && userData.ownerApplicationStatus === 'approved' && stationSnap.data().ownerId === uid;
  if (!admin && !owner) throw new HttpsError('permission-denied', 'You are not allowed to update this station.');
  const patch = { availability, updatedAt: FieldValue.serverTimestamp() };
  if (pricePerKg !== undefined) {
    if (typeof pricePerKg !== 'number' || pricePerKg < 0) throw new HttpsError('invalid-argument', 'Invalid price.');
    patch.pricePerKg = pricePerKg;
  }
  if (queueCount !== undefined) {
    if (!Number.isInteger(queueCount) || queueCount < 0) throw new HttpsError('invalid-argument', 'Invalid queue count.');
    patch.queueCount = queueCount;
  }
  await stationRef.update(patch);
  return { ok: true };
});
