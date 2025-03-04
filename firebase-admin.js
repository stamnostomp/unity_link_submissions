import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js';
import { getDatabase, ref, get, update, onValue } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';
import {
  getAuth,
  signInWithEmailAndPassword,
  onAuthStateChanged,
  signOut
} from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js';

// Your web app's Firebase configuration

// Import the functions you need from the SDKs you need
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
const auth = getAuth(app);

/**
 * Initialize the Firebase integration with the Elm app
 * @param {Object} elmApp - The Elm application instance
 */
export function initializeFirebase(elmApp) {
  // Handle authentication state changes
  onAuthStateChanged(auth, (user) => {
    if (user) {
      // User is signed in
      const userData = {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName || user.email,
      };
      console.log("User is signed in:", userData);
      elmApp.ports.receiveAuthState.send({
        user: userData,
        isSignedIn: true
      });

      // Now that user is signed in, we can start listening for submissions
      setupSubmissionListeners(elmApp);
    } else {
      // User is signed out
      console.log("User is signed out");
      elmApp.ports.receiveAuthState.send({
        user: null,
        isSignedIn: false
      });
    }
  });

  // Handle sign in requests from Elm
  elmApp.ports.signIn.subscribe(function(credentials) {
    const { email, password } = credentials;

    signInWithEmailAndPassword(auth, email, password)
      .then((userCredential) => {
        // Successful sign-in is handled by onAuthStateChanged
        elmApp.ports.receiveAuthResult.send({
          success: true,
          message: "Sign in successful!"
        });
      })
      .catch((error) => {
        console.error("Error signing in:", error);
        elmApp.ports.receiveAuthResult.send({
          success: false,
          message: getAuthErrorMessage(error.code)
        });
      });
  });

  // Handle sign out requests from Elm
  elmApp.ports.signOut.subscribe(function() {
    signOut(auth)
      .then(() => {
        // Successful sign-out is handled by onAuthStateChanged
      })
      .catch((error) => {
        console.error("Error signing out:", error);
      });
  });

  // Other functionality (fetch submissions, save grades) only works when authenticated
  elmApp.ports.requestSubmissions.subscribe(function() {
    if (auth.currentUser) {
      fetchSubmissions(elmApp);
    } else {
      console.warn("Cannot fetch submissions: User not authenticated");
    }
  });

  elmApp.ports.saveGrade.subscribe(function(data) {
    if (auth.currentUser) {
      saveGrade(data, elmApp);
    } else {
      console.warn("Cannot save grade: User not authenticated");
      elmApp.ports.gradeResult.send("Error: Not authenticated");
    }
  });
}

/**
 * Set up listeners for submissions data after authentication
 * @param {Object} elmApp - The Elm application instance
 */
function setupSubmissionListeners(elmApp) {
  // Initial fetch
  fetchSubmissions(elmApp);

  // Set up real-time updates
  const submissionsRef = ref(database, 'submissions');
  onValue(submissionsRef, (snapshot) => {
    if (snapshot.exists()) {
      const data = snapshot.val();
      // Convert Firebase object to array of submissions with IDs
      const submissions = Object.entries(data).map(([id, submission]) => {
        return {
          id,
          ...submission
        };
      });

      elmApp.ports.receiveSubmissions.send(submissions);
    } else {
      elmApp.ports.receiveSubmissions.send([]);
    }
  });
}

/**
 * Fetch all submissions from Firebase
 * @param {Object} elmApp - The Elm application instance
 */
function fetchSubmissions(elmApp) {
  const submissionsRef = ref(database, 'submissions');

  get(submissionsRef)
    .then((snapshot) => {
      if (snapshot.exists()) {
        const data = snapshot.val();
        // Convert Firebase object to array of submissions with IDs
        const submissions = Object.entries(data).map(([id, submission]) => {
          return {
            id,
            ...submission
          };
        });

        elmApp.ports.receiveSubmissions.send(submissions);
      } else {
        // Return empty array if no submissions
        elmApp.ports.receiveSubmissions.send([]);
      }
    })
    .catch((error) => {
      console.error("Error fetching submissions:", error);
      elmApp.ports.receiveSubmissions.send([]);
    });
}

/**
 * Save a grade to Firebase
 * @param {Object} data - The grade data to save
 * @param {Object} elmApp - The Elm application instance
 */
function saveGrade(data, elmApp) {
  const submissionId = data.submissionId;
  const grade = data.grade;

  // Add the current user's email to the grade
  grade.gradedBy = auth.currentUser.email;

  const submissionRef = ref(database, `submissions/${submissionId}`);

  // Update the grade for the submission
  update(submissionRef, { grade })
    .then(() => {
      elmApp.ports.gradeResult.send("Success: Grade saved successfully");
    })
    .catch((error) => {
      elmApp.ports.gradeResult.send("Error: " + error.message);
      console.error("Error saving grade:", error);
    });
}

/**
 * Get a user-friendly error message for authentication errors
 * @param {string} errorCode - The Firebase error code
 * @return {string} A user-friendly error message
 */
function getAuthErrorMessage(errorCode) {
  switch (errorCode) {
    case 'auth/invalid-email':
      return 'The email address is not valid.';
    case 'auth/user-disabled':
      return 'This account has been disabled.';
    case 'auth/user-not-found':
      return 'No account found with this email.';
    case 'auth/wrong-password':
      return 'Incorrect password.';
    case 'auth/too-many-requests':
      return 'Too many failed login attempts. Please try again later.';
    case 'auth/network-request-failed':
      return 'Network error. Please check your connection.';
    default:
      return 'An error occurred during authentication. Please try again.';
  }
}
