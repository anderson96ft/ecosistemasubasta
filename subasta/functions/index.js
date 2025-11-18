// functions/index.js

// --- 1. IMPORTACIONES REQUERIDAS ---
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
// Asegúrate de incluir Timestamp y FieldValue
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getAuth } = require("firebase-admin/auth");
const { beforeUserCreated } = require("firebase-functions/v2/identity");
const admin = require("firebase-admin"); // Necesario para FieldValue.arrayUnion

// Inicializa los servicios de Firebase
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// --- 2. FUNCIÓN AUXILIAR 'isAdmin' ---
const isAdmin = async (uid) => {
    if (!uid) return false;
    const adminDoc = await db.collection('admins').doc(uid).get();
    return adminDoc.exists;
};

// ============================================================================
// ¡¡¡NUEVA FUNCIÓN DE TRIGGER DE CHAT!!!
// Se ejecuta cada vez que se crea un nuevo mensaje en CUALQUIER chat.
// ============================================================================
exports.sendChatNotification = onDocumentCreated("conversations/{conversationId}/messages/{messageId}", async (event) => {

    // 1. Obtiene los datos del mensaje que se acaba de crear
    const messageData = event.data.data();
    if (!messageData) {
        console.log("No hay datos en el mensaje, saliendo.");
        return null;
    }

    const senderId = messageData.senderId;
    const messageText = messageData.text;
    const conversationId = event.params.conversationId;

    // 2. Obtiene el documento de la conversación para saber quiénes son los participantes
    const convoRef = db.collection('conversations').doc(conversationId);
    const convoDoc = await convoRef.get();
    if (!convoDoc.exists) {
        console.log(`Error: No se encontró la conversación ${conversationId}`);
        return null;
    }

    const convoData = convoDoc.data();

    // Si la conversación está cerrada, no envía notificaciones
    if (convoData.status === 'closed') {
        console.log(`Conversación ${conversationId} está cerrada, no se envía notificación.`);
        return null;
    }

    const participants = convoData.participants;
    const productModel = convoData.productModel || 'un artículo';

    // 3. Determina quién es el DESTINATARIO
    const recipientId = participants.find(uid => uid !== senderId);

    if (!recipientId) {
        console.log("No se pudo encontrar un destinatario para este mensaje.");
        return null;
    }

    // 4. Obtiene el nombre/email del remitente para la notificación
    let senderName = 'Alguien';
    if (await isAdmin(senderId)) { // Usa tu helper
        senderName = 'Administrador';
    } else {
        const userProfile = await db.collection('users').doc(senderId).get();
        senderName = userProfile.data()?.email || 'Usuario';
    }

    // 5. Obtiene los tokens de dispositivo (FCM) del destinatario
    const devicesRef = db.collection('users').doc(recipientId).collection('devices');
    const devicesSnapshot = await devicesRef.get();

    if (devicesSnapshot.empty) {
        console.log(`El destinatario ${recipientId} no tiene tokens de dispositivo.`);
        return null;
    }

    const tokens = devicesSnapshot.docs.map(snap => snap.data().token);

    // 6. Construye y envía la notificación push
    // --- INICIO DE LA CORRECCIÓN ---

    // 1. Renombra 'payload' a 'message' y añade 'tokens' DENTRO del objeto
    const message = {
        data: {
            // --- INICIO DE LA MODIFICACIÓN ---
            // Movemos el contenido visual al bloque 'data' para tener control total en la app
            "title": `Nuevo mensaje de ${senderName} (Sobre: ${productModel})`,
            "body": messageText,
            // --- FIN DE LA MODIFICACIÓN ---
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "screen": "ChatDetailScreen",
            "conversationId": conversationId,
            "productId": conversationId.split('_')[0] // Usar siempre el ID de la conversación como fuente de verdad
        },
        apns: { // Configuración específica de Apple
           payload: {
                aps: {
                    sound: "default"
                }
           }
        },
        tokens: tokens // <-- Añade los tokens aquí
    };

    try {
        // 2. Cambia 'sendToDevice' por 'sendEachForMulticast'
        const response = await messaging.sendEachForMulticast(message);
        
        // --- FIN DE LA CORRECCIÓN ---

        console.log(`Notificación de chat enviada a ${recipientId}. Éxitos: ${response.successCount}, Fallos: ${response.failureCount}`);

        // --- INICIO DE LA CORRECCIÓN ---
        // Solo intenta limpiar tokens si hubo fallos Y si el array 'results' existe
        if (response.failureCount > 0 && response.results) {
            response.results.forEach((result, index) => {
                const error = result.error;
                if (error) {
                    console.error('Fallo al enviar notificación al token:', tokens[index], error);
                    if (error.code === 'messaging/registration-token-not-registered' ||
                        error.code === 'messaging/invalid-registration-token') {
                        devicesRef.doc(tokens[index]).delete();
                    }
                }
            });
        }
        // --- FIN DE LA CORRECCIÓN ---

    } catch (error) {
        console.error("Error al enviar notificaciones de chat:", error);
    }

    return null;
});

// ============================================================================
// --- FUNCIÓN 'confirmSale' MODIFICADA ---
// ============================================================================
exports.confirmSale = onCall(async (request) => {
    const { data, auth } = request;
    if (!auth || !(await isAdmin(auth.uid))) {
        throw new HttpsError("permission-denied", "No tienes permisos de administrador.");
    }
    const { productId } = data;
    if (!productId) {
        throw new HttpsError("invalid-argument", "Se requiere el ID del producto.");
    }

    try {
        const productRef = db.collection("products").doc(productId);
        const productDoc = await productRef.get();

        if (!productDoc.exists) {
            throw new HttpsError("not-found", "El producto ya no existe.");
        }

        const productData = productDoc.data();
        const winnerId = productData.winnerId;

        if (!winnerId) {
            throw new HttpsError("failed-precondition", "Este producto no tiene un ganador asignado.");
        }

        const batch = db.batch();

        // 1. Marca el producto como 'sold'
        batch.update(productRef, { status: "sold" });

        // 2. MODIFICACIÓN: Cierra el chat con el ganador
        const conversationId = `${productId}_${winnerId}`;
        const chatRoomRef = db.collection("conversations").doc(conversationId);

        // Usamos 'set' con 'merge: true' para crear o actualizar el chat de forma segura
        batch.set(chatRoomRef, {
            status: "closed",
            lastMessage: "Esta conversación ha sido cerrada por el administrador.",
            lastMessageTimestamp: Timestamp.now(),
            lastMessageSenderId: auth.uid
        }, { merge: true }); // 'merge: true' es clave aquí

        await batch.commit();

        return { success: true, message: "Venta confirmada y chat cerrado." };

    } catch (error) {
        console.error("Error al confirmar la venta:", error);
        if (error instanceof HttpsError) { throw error; }
        throw new HttpsError("internal", "Ocurrió un error al confirmar la venta.");
    }
});

// ============================================================================
// --- FUNCIÓN 'annulBid' MODIFICADA ---
// ============================================================================
exports.annulBid = onCall(async (request) => {
    const { data, auth } = request;
    if (!auth || !(await isAdmin(auth.uid))) {
        throw new HttpsError("permission-denied", "No tienes permisos de administrador.");
    }

    // El 'highestBidId' es el ID del *documento* de la puja a anular.
    const { productId, highestBidId, annulledUserId } = data;

    if (!productId || !highestBidId || !annulledUserId) {
        throw new HttpsError("invalid-argument", "Faltan datos (productId, highestBidId, annulledUserId).");
    }

    const productRef = db.collection("products").doc(productId);
    const bidsRef = productRef.collection("bids");

    try {
        const batch = db.batch();

        // 1. Elimina la puja anulada de la subcolección
        batch.delete(bidsRef.doc(highestBidId));

        // 2. Busca la *siguiente* puja más alta (excluyendo al usuario anulado)
        const remainingBidsSnapshot = await bidsRef
            .orderBy("amount", "desc")
            .get();

        // Filtramos manualmente para encontrar el siguiente pujador *diferente*
        let newHighestBidderId = null;
        let newCurrentPrice = 0;
        const productData = (await productRef.get()).data();

        const allRemainingBids = remainingBidsSnapshot.docs.map(d => d.data());
        const nextHighestBid = allRemainingBids.find(b => b.userId !== annulledUserId);

        if (nextHighestBid) {
            // Si hay otra puja, promuévela
            newHighestBidderId = nextHighestBid.userId;
            newCurrentPrice = nextHighestBid.amount;
        } else {
            // Si no quedan más pujas, resetea al precio inicial (si existe)
            newCurrentPrice = productData.startPrice || 0; // Asumiendo que tienes un 'startPrice'
        }

        // 3. Actualiza el producto con el nuevo ganador y precio
        batch.update(productRef, {
            winnerId: newHighestBidderId, // Actualiza el 'winnerId' para el admin
            highestBidderId: newHighestBidderId,
            currentPrice: newCurrentPrice,
            bidderIds: FieldValue.arrayRemove(annulledUserId)
        });

        // --- 4. MODIFICACIÓN: Cierra el chat con el usuario anulado ---
        const conversationId = `${productId}_${annulledUserId}`;
        const chatRoomRef = db.collection("conversations").doc(conversationId);

        // Usamos 'set' con 'merge: true' para crear o actualizar el chat de forma segura
        batch.set(chatRoomRef, {
            status: "closed",
            lastMessage: "Tu puja ha sido anulada por el administrador.",
            lastMessageTimestamp: Timestamp.now(),
            lastMessageSenderId: auth.uid
        }, { merge: true }); // 'merge: true' es clave aquí

        await batch.commit();

        return { success: true, message: "Puja anulada. El siguiente pujador ha sido promovido." };
    } catch (error) {
        console.error("Error al anular la puja:", error);
        if (error instanceof HttpsError) { throw error; }
        throw new HttpsError("internal", "Ocurrió un error al anular la puja.");
    }
});


// ============================================================================
// --- RESTO DE TUS FUNCIONES (SIN CAMBIOS) ---
// ============================================================================

exports.beforeUserCreated = beforeUserCreated(async (event) => {
    const user = event.data;
    const phoneNumber = user.phoneNumber;
    if (phoneNumber) {
        console.log(`Verificando el número de teléfono: ${phoneNumber}`);
        const bannedPhoneRef = db.collection('bannedPhoneNumbers').doc(phoneNumber);
        const doc = await bannedPhoneRef.get();
        if (doc.exists) {
            console.log(`Registro bloqueado para el número baneado: ${phoneNumber}`);
            throw new HttpsError("invalid-argument", "Este número de teléfono ha sido suspendido.");
        }
    }
    console.log(`Permitiendo registro para el usuario: ${user.uid}`);
    return;
});

exports.listUsers = onCall(async (request) => {
    const { auth } = request;
    if (!auth || !(await isAdmin(auth.uid))) {
        throw new HttpsError("permission-denied", "No tienes permisos de administrador.");
    }
    try {
        const userRecords = await getAuth().listUsers(1000);
        const users = userRecords.users.map((user) => ({
            uid: user.uid,
            email: user.email,
            creationTime: user.metadata.creationTime,
            lastSignInTime: user.metadata.lastSignInTime,
        }));
        return { users: users };
    } catch (error) {
        console.error("Error al listar usuarios:", error);
        throw new HttpsError("internal", "Ocurrió un error al obtener la lista de usuarios.");
    }
});

exports.closeAuctions = onSchedule("every 1 minutes", async (event) => {
    const now = Timestamp.now();
    console.log("Ejecutando closeAuctions, hora actual:", now.toDate());

    const query = db
        .collection("products")
        .where("saleType", "==", "auction")
        .where("status", "==", "active")
        .where("endTime", "<=", now);

    const expiredAuctions = await query.get();

    if (expiredAuctions.empty) {
        console.log("No hay subastas para cerrar.");
        return;
    }

    const batch = db.batch();
    const notificationsToSend = [];

    expiredAuctions.forEach((doc) => {
        const auctionData = doc.data();
        const winnerId = auctionData.highestBidderId || null;

        console.log(`Cerrando subasta: ${doc.id}. Ganador: ${winnerId || "Ninguno"}`);

        batch.update(doc.ref, {
            status: "pending_confirmation",
            winnerId: winnerId,
        });

        if (winnerId) {
            notificationsToSend.push({
                winnerId: winnerId,
                productTitle: auctionData.model || 'un artículo',
                productId: doc.id,
            });
        }
    });

    await batch.commit();
    console.log(`Proceso de cierre completado. Se cerraron ${expiredAuctions.size} subastas.`);

    for (const notification of notificationsToSend) {
        console.log(`Enviando notificación de victoria a: ${notification.winnerId}`);
        const devicesRef = db.collection('users').doc(notification.winnerId).collection('devices');
        const devicesSnapshot = await devicesRef.get();

        if (!devicesSnapshot.empty) {
            const tokens = devicesSnapshot.docs.map(snap => snap.data().token);
            const message = {
                tokens: tokens,
                notification: {
                    title: '¡Has ganado una subasta! 🏆',
                    body: `¡Felicidades! Has ganado la subasta del ${notification.productTitle}. Un vendedor te contactará pronto.`,
                },
                data: {
                    productId: notification.productId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                }
            };
            const response = await messaging.sendEachForMulticast(message);
            console.log(`Notificación de victoria enviada. Éxitos: ${response.successCount}, Fallos: ${response.failureCount}`);
        }
    }
});

exports.buyNow = onCall(async (request) => {
    const { data, auth } = request;
    if (!auth) {
        throw new HttpsError("unauthenticated", "Debes estar autenticado para comprar un producto.");
    }
    const userDocRef = db.collection('users').doc(auth.uid);
    const userDoc = await userDocRef.get();
    if (userDoc.exists && userDoc.data().status === 'banned') {
        throw new HttpsError("permission-denied", "Tu cuenta ha sido suspendida y no puedes realizar compras.");
    }
    const { productId } = data;
    if (!productId) {
        throw new HttpsError("invalid-argument", "Se requiere el ID del producto.");
    }
    const userId = auth.uid;
    const productRef = db.collection("products").doc(productId);
    try {
        await db.runTransaction(async (transaction) => {
            const productDoc = await transaction.get(productRef);
            if (!productDoc.exists) {
                throw new HttpsError("not-found", "El producto ya no existe.");
            }
            const productData = productDoc.data();
            if (productData.saleType !== "directSale") {
                throw new HttpsError("failed-precondition", "Este producto no es de venta directa.");
            }
            if (productData.status !== "active") {
                throw new HttpsError("failed-precondition", "Este producto ya no está disponible para la venta.");
            }
            if (productData.sellerId === userId) {
                throw new HttpsError("failed-precondition", "No puedes comprar tu propio producto.");
            }
            transaction.update(productRef, {
                status: "sold",
                buyerId: userId,
            });
        });
        console.log(`Venta exitosa del producto ${productId} al usuario ${userId}`);
        return { success: true, message: "¡Compra realizada con éxito!" };
    } catch (error) {
        console.error("Error al procesar la compra:", error);
        if (error instanceof HttpsError) {
            throw error;
        } else {
            throw new HttpsError("internal", "Ocurrió un error al procesar tu compra.");
        }
    }
});

exports.placeBid = onCall(async (request) => {
    const { data, auth } = request;
    if (!auth) {
        throw new HttpsError("unauthenticated", "Debes estar autenticado para realizar una puja.");
    }
    const userDocRef = db.collection('users').doc(auth.uid);
    const userDoc = await userDocRef.get();
    if (userDoc.exists && userDoc.data().status === 'banned') {
        throw new HttpsError("permission-denied", "Tu cuenta ha sido suspendida y no puedes realizar pujas.");
    }
    const { productId, bidAmount } = data;
    if (!productId || typeof bidAmount !== "number" || bidAmount <= 0) {
        throw new HttpsError("invalid-argument", "Los datos de la puja no son válidos.");
    }

    const newBidderId = auth.uid;
    const productRef = db.collection("products").doc(productId);
    const bidsRef = productRef.collection("bids");

    try {
        let previousBidderId = null;
        let productTitle = '';

        await db.runTransaction(async (transaction) => {
            const productDoc = await transaction.get(productRef);
            if (!productDoc.exists) { throw new HttpsError("not-found", "El producto no existe."); }

            const productData = productDoc.data();
            productTitle = productData.model || 'tu artículo';
            previousBidderId = productData.highestBidderId || null;

            if (productData.status !== "active") { throw new HttpsError("failed-precondition", "La subasta ya no está activa."); }
            const currentPrice = productData.currentPrice || 0;
            if (bidAmount <= currentPrice) { throw new HttpsError("failed-precondition", `Tu puja debe ser mayor que el precio actual de \$${currentPrice.toFixed(2)}.`); }

            const newBidRef = bidsRef.doc();
            transaction.set(newBidRef, { userId: newBidderId, amount: bidAmount, timestamp: Timestamp.now() });

            transaction.update(productRef, {
                currentPrice: bidAmount,
                highestBidderId: newBidderId,
                bidderIds: FieldValue.arrayUnion(newBidderId),
            });
        });

        if (previousBidderId && previousBidderId !== newBidderId) {
            const devicesRef = db.collection('users').doc(previousBidderId).collection('devices');
            const devicesSnapshot = await devicesRef.get();
            if (!devicesSnapshot.empty) {
                const tokens = devicesSnapshot.docs.map(snap => snap.data().token);
                const message = {
                    tokens: tokens,
                    notification: { title: '¡Puja superada!', body: `Alguien ha superado tu puja en el ${productTitle}.` },
                    data: { productId: productId, click_action: 'FLUTTER_NOTIFICATION_CLICK' }
                };
                const response = await messaging.sendEachForMulticast(message);
                console.log(`Notificaciones enviadas. Éxitos: ${response.successCount}, Fallos: ${response.failureCount}`);
                // --- CORRECCIÓN AQUÍ TAMBIÉN ---
                if (response.failureCount > 0 && response.results) {
                    response.results.forEach((result, index) => {
                        const error = result.error;
                        if (error) {
                            console.error('Fallo al enviar notificación de puja superada al token:', tokens[index], error);
                            if (error.code === 'messaging/registration-token-not-registered' ||
                                error.code === 'messaging/invalid-registration-token') {
                                // El ID del documento es el propio token.
                                devicesRef.doc(tokens[index]).delete();
                            }
                        }
                    });
                }
                // --- FIN DE LA CORRECCIÓN ---
            }
        }
        return { success: true, message: "¡Puja realizada con éxito!" };
    } catch (error) {
        console.error("Error al procesar la puja:", error);
        if (error instanceof HttpsError) { throw error; }
        else { throw new HttpsError("internal", "Ocurrió un error al procesar tu puja."); }
    }
});

exports.reportIncident = onCall(async (request) => {
    const { data, auth } = request;
    if (!auth || !(await isAdmin(auth.uid))) { throw new HttpsError("permission-denied", "No tienes permisos de administrador."); }
    const { reportedUserId, productId, productModel, bidAmount, reason } = data;
    if (!reportedUserId || !productId || !bidAmount || !reason) { throw new HttpsError("invalid-argument", "Faltan datos para reportar el incidente."); }

    try {
        const incidentRef = db.collection('users').doc(reportedUserId).collection('incidents').doc();
        await incidentRef.set({
            productId: productId, productModel: productModel || 'N/A', bidAmount: bidAmount, reason: reason,
            reportedAt: Timestamp.now(), status: "unresolved", userExplanation: null,
        });
        return { success: true, message: "Incidente reportado con éxito." };
    } catch (error) {
        console.error("Error al reportar incidente:", error);
        throw new HttpsError("internal", "Ocurrió un error al guardar el incidente.");
    }
});

exports.banUser = onCall(async (request) => {
    const { data, auth } = request;
    if (!auth || !(await isAdmin(auth.uid))) {
        throw new HttpsError("permission-denied", "No tienes permisos de administrador.");
    }
    const { userIdToBan } = data;
    if (!userIdToBan) {
        throw new HttpsError("invalid-argument", "Se requiere el ID del usuario a banear.");
    }
    try {
        const userDocRef = db.collection('users').doc(userIdToBan);
        const userDoc = await userDocRef.get();
        if (!userDoc.exists) {
            throw new HttpsError("not-found", "El usuario no existe en la base de datos.");
        }
        const userData = userDoc.data();
        const phoneNumber = userData.phone;

        await getAuth().updateUser(userIdToBan, { disabled: true });
        await userDocRef.update({ status: 'banned' });

        if (phoneNumber) {
            const bannedPhoneRef = db.collection('bannedPhoneNumbers').doc(phoneNumber);
            await bannedPhoneRef.set({
                bannedAt: Timestamp.now(),
                reason: `Baneado por el admin ${auth.uid}`,
                bannedUserId: userIdToBan,
            });
        }
        console.log(`Usuario ${userIdToBan} baneado por el admin ${auth.uid}`);
        return { success: true, message: "Usuario baneado con éxito." };
    } catch (error) {
        console.error("Error al banear usuario:", error);
        throw new HttpsError("internal", "Ocurrió un error al banear al usuario.");
    }
});