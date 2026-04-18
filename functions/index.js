const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnCreate = functions.firestore
    .document("notifications/{notificationId}")
    .onCreate(async (snap, context) => {
      const data = snap.data();
      const title = data.title;
      const message = data.message;
      const toAll = data.toAll;
      const to = data.to || [];

      const tokens = [];

      if (toAll) {
        // Sab users ke device token
        const usersSnapshot = await admin.firestore().collection("users").get();
        usersSnapshot.forEach((doc) => {
          if (doc.data().fcmToken) tokens.push(doc.data().fcmToken);
        });
      } else {
        // Selected users ke token
        for (const uid of to) {
          const userDoc = await admin.firestore()
              .collection("users")
              .doc(uid)
              .get();
          if (userDoc.exists && userDoc.data().fcmToken) {
            tokens.push(userDoc.data().fcmToken);
          }
        }
      }

      if (tokens.length === 0) return null;

      const payload = {
        notification: {
          title: title,
          body: message,
        },
      };

      return admin.messaging().sendToDevice(tokens, payload);
    });
