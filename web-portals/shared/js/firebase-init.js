/**
 * Firebase application initialization.
 */

const firebaseConfig = {
  apiKey: "AIzaSyAYiwgFFldS2Umf2LZ8bCPbX5hPacVScvE",
  authDomain: "sawari-1591d.firebaseapp.com",
  projectId: "sawari-1591d",
  storageBucket: "sawari-1591d.firebasestorage.app",
  messagingSenderId: "100873074755",
  appId: "1:100873074755:android:b44af8d3377b8283c53cf6"
};

try {
  firebase.initializeApp(firebaseConfig);
  console.log('Firebase initialized');
} catch (error) {
  console.error('Firebase initialization failed:', error);
}

window.firebaseApp = firebase.app();
window.firebaseAuth = firebase.auth();
