// submissions-firebase.js
// Import Firebase modules using CDN URLs
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js';
import { getDatabase, ref, set } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyA_sP8BE2C6MLWATQNoLM_U-_VDigHTImg",
  authDomain: "elm-unity-subs.firebaseapp.com",
  databaseURL: "https://elm-unity-subs-default-rtdb.firebaseio.com",
  projectId: "elm-unity-subs",
  storageBucket: "elm-unity-subs.firebasestorage.app",
  messagingSenderId: "94290689528",
  appId: "1:94290689528:web:74047dce17d27e00172a0d",
  measurementId: "G-90YCVPGV6M"
};


// Initialize Firebase
const app = initializeApp(firebaseConfig);
const database = getDatabase(app);

/**
 * Initialize the Firebase integration with the Elm app
 * @param {Object} elmApp - The Elm application instance
 */
export function initializeFirebase(elmApp) {
  // Listen for saveToFirebase commands from Elm
  elmApp.ports.saveToFirebase.subscribe(function(data) {
    saveSubmission(data, elmApp);
  });
}

/**
 * Save a game submission to Firebase
 * @param {Object} data - The submission data to save
 * @param {Object} elmApp - The Elm application instance
 */
function saveSubmission(data, elmApp) {
  console.log("Received data from Elm:", data);

  // Generate a unique key for the submission or use the provided ID
  const submissionId = data.submissionId || generateSubmissionId(data);

  // Save to Firebase
  set(ref(database, 'submissions/' + submissionId), data)
    .then(() => {
      console.log("Data saved successfully");
      // Send success message back to Elm
      elmApp.ports.firebaseSaveResult.send("Success: Data saved successfully");
    })
    .catch((error) => {
      console.error("Firebase save error:", error);
      // Send error message back to Elm
      elmApp.ports.firebaseSaveResult.send("Error: " + error.message);
    });
}

/**
 * Generate a unique ID for the submission
 * @param {Object} data - The submission data
 * @return {string} A unique ID
 */
function generateSubmissionId(data) {
  // Create a unique ID based on name and timestamp
  const timestamp = Date.now();
  const namePart = data.studentName ? data.studentName.replace(/[^a-z0-9]/gi, '') : '';
  return `${namePart}-${timestamp}`;
}
