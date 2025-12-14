const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.deleteOldDelivered = onSchedule({
  schedule: "every 1 hours",
  timeZone: "Asia/Muscat", // your timezone (Oman)
  timeoutSeconds: 300,
}, async (event) => {
  try {
    const now = admin.firestore.Timestamp.now();
    const twelveHoursAgo = new admin.firestore.Timestamp(
      now.seconds - (12 * 60 * 60),
      now.nanoseconds
    );

    const oldDelivered = await admin.firestore()
      .collection('repairs')
      .where('status', '==', 'Delivered')
      .where('lastUpdated', '<=', twelveHoursAgo)
      .get();

    if (oldDelivered.empty) {
      logger.info('No old delivered devices to delete');
      return null;
    }

    const batch = admin.firestore().batch();
    oldDelivered.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    logger.info(`Deleted ${oldDelivered.size} old delivered devices`);
    return null;
  } catch (error) {
    logger.error('Error deleting old devices', error);
    throw error;
  }
});