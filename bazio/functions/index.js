const { onDocumentCreated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

async function sendNotification({ recipientUid, type, title, body, routePath, chatId }) {
  const notifRef = chatId
    ? db.collection("users").doc(recipientUid).collection("notifications").doc(chatId)
    : db.collection("users").doc(recipientUid).collection("notifications").doc();

  await notifRef.set({
    type,
    title,
    body,
    routePath,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  const userSnap = await db.collection("users").doc(recipientUid).get();
  const fcmToken = userSnap.data()?.fcmToken;
  if (!fcmToken) return;

  const data = { routePath: routePath ?? "" };
  if (chatId) data.chatId = chatId;

  try {
    await getMessaging().send({
      token: fcmToken,
      notification: { title, body },
      data,
      android: {
        collapseKey: chatId ?? type,  // ✅ bonne place
        priority: "high",
        notification: {
          channelId: "bazio_main",
          sound: "default",
          tag: chatId ?? type,
        },
      },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
    });
  } catch (err) {
    if (
      err.code === "messaging/registration-token-not-registered" ||
      err.code === "messaging/invalid-registration-token"
    ) {
      await db.collection("users").doc(recipientUid).update({
        fcmToken: FieldValue.delete(),
      });
    }
    console.error(`[FCM] Erreur pour ${recipientUid}:`, err.message);
  }
}

exports.onNewMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const messageData = event.data.data();
    const { chatId } = event.params;

    if (messageData.isSystem === true) return;

    const senderId = messageData.senderId;
    const text = messageData.text ?? "";

    const chatSnap = await db.collection("chats").doc(chatId).get();
    if (!chatSnap.exists) return;

    const chatData = chatSnap.data();
    const participants = chatData.participants ?? [];
    const listingTitle = chatData.listingTitle ?? "Annonce";

    const recipientUid = participants.find((uid) => uid !== senderId);
    if (!recipientUid) return;

    const senderSnap = await db.collection("users").doc(senderId).get();
    const senderName = senderSnap.data()?.name ?? "Quelqu'un";

    const preview = text.length > 60 ? text.substring(0, 60) + "…" : text;

    await sendNotification({
      recipientUid,
      type: "message",
      title: listingTitle,
      body: `${senderName} : ${preview || "Nouveau message"}`,
      routePath: `/messages/${chatId}?listingTitle=${encodeURIComponent(listingTitle)}`,
      chatId, // <- transmis pour grouper les notifs
    });
  }
);

exports.onNewReview = onDocumentCreated(
  "users/{sellerId}/reviews/{reviewId}",
  async (event) => {
    const reviewData = event.data.data();
    const { sellerId } = event.params;

    const authorName = reviewData.authorName ?? "Quelqu'un";
    const rating = reviewData.rating ?? 0;
    const listingTitle = reviewData.listingTitle ?? "votre annonce";

    const stars = "★".repeat(rating) + "☆".repeat(Math.max(0, 5 - rating));

    await sendNotification({
      recipientUid: sellerId,
      type: "review",
      title: `${authorName} vous a laissé un avis`,
      body: `${stars}  "${listingTitle}"`,
      routePath: `/seller/${sellerId}`,
    });
  }
);

exports.onUserDeleted = onDocumentDeleted(
  { document: "users/{uid}" },
  async (event) => {
    const uid = event.params.uid;
    console.log(`[onUserDeleted] Suppression en cascade pour uid=${uid}`);

    const bucket = getStorage().bucket();

    const listingsSnap = await db
      .collection("listings")
      .where("sellerId", "==", uid)
      .get();

    console.log(`[onUserDeleted] ${listingsSnap.size} annonce(s) trouvée(s)`);

    try {
      await bucket.deleteFiles({ prefix: `listings/${uid}/` });
      console.log(`[onUserDeleted] Dossier listings/${uid}/ supprimé`);
    } catch (e) {
      console.error("[onUserDeleted] Erreur suppression Storage :", e.message);
    }

    const BATCH_LIMIT = 500;
    const listingDocs = listingsSnap.docs;

    for (let i = 0; i < listingDocs.length; i += BATCH_LIMIT) {
      const batch = db.batch();
      listingDocs.slice(i, i + BATCH_LIMIT).forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();
    }

    console.log(`[onUserDeleted] Annonces supprimées`);

    const favSnap = await db
      .collection("users")
      .doc(uid)
      .collection("favorites")
      .get();

    if (!favSnap.empty) {
      for (let i = 0; i < favSnap.docs.length; i += BATCH_LIMIT) {
        const batch = db.batch();
        favSnap.docs.slice(i, i + BATCH_LIMIT).forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();
      }
      console.log(`[onUserDeleted] ${favSnap.size} favori(s) supprimé(s)`);
    }

    console.log(`[onUserDeleted] ✅ Cascade terminée pour uid=${uid}`);
  }
);