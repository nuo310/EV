const db = require("./firebase");

// Get email from command line arguments
const email = process.argv[2];

if (!email) {
  console.error("\x1b[31mError: Please provide a user email address.\x1b[0m");
  console.log("Usage: node promote-user.js <email>");
  process.exit(1);
}

async function promote() {
  try {
    console.log(`🔍 Searching for user with email: ${email}...`);
    
    // Find the user document in the Firestore "users" collection
    const usersRef = db.collection("users");
    const snapshot = await usersRef.where("email", "==", email.trim()).limit(1).get();
    
    if (snapshot.empty) {
      console.error(`\x1b[31mError: No user found with email "${email}" in Firestore.\x1b[0m`);
      console.log("Please check the email address or register the user in the client app first.");
      process.exit(1);
    }
    
    const userDoc = snapshot.docs[0];
    const userId = userDoc.id;
    const userData = userDoc.data();
    
    console.log(`Found user: "${userData.name || 'No Name'}" (UID: ${userId})`);
    console.log(`Current role: "${userData.role || 'user'}"`);
    
    console.log("⚡ Promoting user to 'admin'...");
    
    // Update the role field to 'admin'
    await usersRef.doc(userId).update({
      role: "admin"
    });
    
    console.log(`\x1b[32mSuccess! User ${email} has been promoted to 'admin'.\x1b[0m`);
    console.log("You can now log in using this account, and you will see the Admin Dashboard options and route.");
    process.exit(0);
  } catch (error) {
    console.error("\x1b[31mFailed to promote user:\x1b[0m", error);
    process.exit(1);
  }
}

promote();
