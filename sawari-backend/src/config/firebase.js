const admin = require('firebase-admin');

let firebaseApp;

try {
  // Initialize using environment variables
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        // Replace escaped newlines in the private key
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      }),
    });
    console.log('Firebase initialized with environment variables');
  } 
  // Fallback: service account JSON file
  else {
    const serviceAccount = require('../../serviceAccountKey.json');
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('Firebase initialized with service account file');
  }
} catch (error) {
  console.warn('Firebase initialization failed:', error.message);
  console.warn('Auth endpoints will not work until Firebase is configured');
}

module.exports = {
  admin,
  auth: admin.auth(),
  
  // Verify Firebase ID token from client
  verifyIdToken: async (idToken) => {
    if (!firebaseApp) {
      throw new Error('Firebase not initialized');
    }
    return admin.auth().verifyIdToken(idToken);
  },
  
  // Create a custom token for a user
  createCustomToken: async (uid, claims = {}) => {
    if (!firebaseApp) {
      throw new Error('Firebase not initialized');
    }
    return admin.auth().createCustomToken(uid, claims);
  },
  
  // Get user by UID
  getUser: async (uid) => {
    if (!firebaseApp) {
      throw new Error('Firebase not initialized');
    }
    return admin.auth().getUser(uid);
  },
  
  // Delete a user
  deleteUser: async (uid) => {
    if (!firebaseApp) {
      throw new Error('Firebase not initialized');
    }
    return admin.auth().deleteUser(uid);
  }
};
