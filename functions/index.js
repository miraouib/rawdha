const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 🔔 Trigger when a new announcement is created
 * Collection: announcements
 */
exports.onAnnouncementCreated = onDocumentCreated(
    "announcements/{announcementId}",
    async (event) => {
        const snap = event.data;
        if (!snap) {
            console.log("No snapshot data");
            return;
        }

        const data = snap.data();

        const rawdhaId = data.rawdhaId;
        const title = data.title;
        const body = data.body || data.content || "";

        if (!rawdhaId || !title) {
            console.log("Missing rawdhaId or title, skipping notification");
            return;
        }

        const topic = `school_${rawdhaId}`;

        const message = {
            topic: topic,
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: data.type || "announcement",
                rawdhaId: rawdhaId,
            },
        };

        try {
            await admin.messaging().send(message);
        } catch (error) {
            console.error("❌ FCM error:", error);
        }
    }
);

/**
 * 🔔 Trigger when a generic notification is saved
 * Collection: notifications (used by Test button and Modules)
 */
exports.onNotificationCreated = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
        const snap = event.data;
        if (!snap) return;

        const data = snap.data();
        const rawdhaId = data.rawdhaId;
        const title = data.title;
        const body = data.body || "";

        if (!rawdhaId || !title) return;

        const topic = `school_${rawdhaId}`;

        const message = {
            topic: topic,
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: data.type || "general",
                rawdhaId: rawdhaId,
            },
        };

        try {
            await admin.messaging().send(message);
        } catch (error) {
            console.error("❌ FCM error:", error);
        }
    }
);
