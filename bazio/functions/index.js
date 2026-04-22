const { onDocumentCreated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

// ════════════════════════════════════════════════════════════════════════
// HELPER — Écrire la notif dans Firestore + envoyer le push FCM
// ════════════════════════════════════════════════════════════════════════

async function sendNotification({ recipientUid, type, title, body, routePath }) {
  // 1. Écrire dans users/{uid}/notifications  →  alimente le badge in-app
  await db
    .collection("users")
    .doc(recipientUid)
    .collection("notifications")
    .add({
      type,        // "message" | "review"
      title,
      body,
      routePath,
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });

  // 2. Récupérer le token FCM du destinataire
  const userSnap = await db.collection("users").doc(recipientUid).get();
  const fcmToken = userSnap.data()?.fcmToken;
  if (!fcmToken) return; // pas de token → la notif in-app suffit

  // 3. Envoyer le push FCM
  try {
    await getMessaging().send({
      token: fcmToken,
      notification: { title, body },
      data: { routePath: routePath ?? "" },
      android: {
        priority: "high",
        notification: {
          channelId: "bazio_main",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
    });
  } catch (err) {
    // Token invalide/expiré → le supprimer
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

// ════════════════════════════════════════════════════════════════════════
// TRIGGER 1 — Nouveau message dans une conversation
// Chemin : chats/{chatId}/messages/{messageId}
// ════════════════════════════════════════════════════════════════════════

exports.onNewMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const messageData = event.data.data();
    const { chatId } = event.params;

    // Ignorer les messages système (vendu / remis en vente)
    if (messageData.isSystem === true) return;

    const senderId = messageData.senderId;
    const text = messageData.text ?? "";

    // Récupérer la conversation pour trouver le destinataire
    const chatSnap = await db.collection("chats").doc(chatId).get();
    if (!chatSnap.exists) return;

    const chatData = chatSnap.data();
    const participants = chatData.participants ?? [];
    const listingTitle = chatData.listingTitle ?? "Annonce";

    // Le destinataire = l'autre participant
    const recipientUid = participants.find((uid) => uid !== senderId);
    if (!recipientUid) return;

    // Récupérer le nom de l'expéditeur
    const senderSnap = await db.collection("users").doc(senderId).get();
    const senderName = senderSnap.data()?.name ?? "Quelqu'un";

    // Tronquer le message si trop long
    const preview = text.length > 60 ? text.substring(0, 60) + "…" : text;

    await sendNotification({
      recipientUid,
      type: "message",
      title: senderName,
      body: preview || "Nouveau message",
      routePath: `/messages/${chatId}?listingTitle=${encodeURIComponent(listingTitle)}`,
    });
  }
);

// ════════════════════════════════════════════════════════════════════════
// TRIGGER 2 — Nouvel avis sur un vendeur
// Chemin : users/{sellerId}/reviews/{reviewId}
// ════════════════════════════════════════════════════════════════════════

exports.onNewReview = onDocumentCreated(
  "users/{sellerId}/reviews/{reviewId}",
  async (event) => {
    const reviewData = event.data.data();
    const { sellerId } = event.params;

    const authorName = reviewData.authorName ?? "Quelqu'un";
    const rating = reviewData.rating ?? 0;
    const listingTitle = reviewData.listingTitle ?? "votre annonce";

    // Étoiles en texte  ex: ★★★★☆
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

// ════════════════════════════════════════════════════════════════════════
// TRIGGER 3 — Suppression d'un utilisateur (cascade)
// Chemin : users/{uid}
// ════════════════════════════════════════════════════════════════════════

exports.onUserDeleted = onDocumentDeleted(
  { document: "users/{uid}" },
  async (event) => {
    const uid = event.params.uid;
    console.log(`[onUserDeleted] Suppression en cascade pour uid=${uid}`);

    const bucket = getStorage().bucket();

    // 1. Récupérer toutes les annonces du vendeur
    const listingsSnap = await db
      .collection("listings")
      .where("sellerId", "==", uid)
      .get();

    console.log(`[onUserDeleted] ${listingsSnap.size} annonce(s) trouvée(s)`);

    // 2. Supprimer le dossier listings/{uid}/ dans Firebase Storage
    try {
      await bucket.deleteFiles({ prefix: `listings/${uid}/` });
      console.log(`[onUserDeleted] Dossier listings/${uid}/ supprimé`);
    } catch (e) {
      console.error("[onUserDeleted] Erreur suppression Storage :", e.message);
    }

    // 3. Supprimer les annonces Firestore en batch
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

    // 4. Supprimer la sous-collection favorites
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