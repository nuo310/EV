const admin = require("firebase-admin");
const path = require("path");

// Load the Firebase Admin Service Account key directly from the project directory
const serviceAccountPath = path.join(__dirname, "ev-app-firebase-service.json");
const serviceAccount = require(serviceAccountPath);

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Firestore database reference
const db = admin.firestore();

console.log("🔥 Successfully connected to Firebase Admin SDK for Project: " + serviceAccount.project_id);

module.exports = db;