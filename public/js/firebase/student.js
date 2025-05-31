// student-firebase.js
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js';
import { getDatabase, ref, get, set, update, query, orderByChild, equalTo, push } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';
import { getAuth, signInAnonymously, onAuthStateChanged } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js';

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
const auth = getAuth(app);

/**
 * Initialize student authentication (anonymous)
 */
function initializeStudentAuth() {
    return new Promise((resolve, reject) => {
        onAuthStateChanged(auth, (user) => {
            if (user) {
                console.log("Student authenticated:", user.uid);
                resolve(user);
            } else {
                console.log("Student not authenticated, signing in anonymously...");
                signInAnonymously(auth)
                    .then((userCredential) => {
                        console.log("Anonymous authentication successful:", userCredential.user.uid);
                        resolve(userCredential.user);
                    })
                    .catch((error) => {
                        console.error("Anonymous authentication failed:", error);
                        reject(error);
                    });
            }
        });
    });
}

/**
 * Sanitize a string for use as a Firebase path
 * @param {string} path - The path to sanitize
 * @return {string} - Sanitized path
 */
function sanitizeFirebasePath(path) {
  // Replace invalid characters with underscores
  return path.replace(/[.#$[\]]/g, '_');
}

/**
 * Helper function to format display name
 * @param {string} name - Name in firstname.lastname format
 * @return {string} Formatted display name
 */
function formatDisplayName(name) {
  const parts = name.split('.');
  if (parts.length !== 2) return name;

  const firstName = parts[0];
  const lastName = parts[1];

  const capitalizedFirst = firstName.charAt(0).toUpperCase() + firstName.slice(1);
  const capitalizedLast = lastName.charAt(0).toUpperCase() + lastName.slice(1);

  return `${capitalizedFirst} ${capitalizedLast}`;
}

/**
 * Initialize the Firebase integration with the Elm app
 * @param {Object} elmApp - The Elm application instance
 */
export function initializeFirebase(elmApp) {
  // Initialize authentication when the module loads
  initializeStudentAuth().catch(error => {
    console.error("Initial authentication failed:", error);
  });

  // Listen for belt requests
  elmApp.ports.requestBelts.subscribe(function() {
    fetchBeltsWithAuth(elmApp);
  });

  // Listen for student search requests
  elmApp.ports.findStudent.subscribe(function(studentName) {
    findStudentWithAuth(studentName, elmApp);
  });

  // Listen for submission save requests
  elmApp.ports.saveSubmission.subscribe(function(submissionData) {
    saveSubmissionWithAuth(submissionData, elmApp);
  });
}

/**
 * Fetch belts with authentication
 * @param {Object} elmApp - The Elm application instance
 */
async function fetchBeltsWithAuth(elmApp) {
  try {
    await initializeStudentAuth();
    await fetchBelts(elmApp);
  } catch (error) {
    console.error("Authentication failed for belts:", error);
    elmApp.ports.receiveBelts.send([]);
  }
}

/**
 * Find student with authentication
 * @param {string} studentName - The name to search for
 * @param {Object} elmApp - The Elm application instance
 */
async function findStudentWithAuth(studentName, elmApp) {
  try {
    await initializeStudentAuth();
    await findStudentByName(studentName, elmApp);
  } catch (error) {
    console.error("Authentication failed for student search:", error);
    elmApp.ports.studentFound.send(null);
  }
}

/**
 * Save submission with authentication
 * @param {Object} submissionData - The submission data to save
 * @param {Object} elmApp - The Elm application instance
 */
async function saveSubmissionWithAuth(submissionData, elmApp) {
  try {
    const user = await initializeStudentAuth();

    // Create submission with proper structure for Firebase push
    const submission = {
      studentId: submissionData.studentId,
      beltLevel: submissionData.beltLevel,
      gameName: submissionData.gameName,
      githubLink: submissionData.githubLink,
      notes: submissionData.notes,
      submissionDate: new Date().toISOString().split('T')[0],
      submittedBy: user.uid // Track anonymous user for debugging
    };

    // Use push() to generate a unique ID
    const submissionsRef = ref(database, 'submissions');
    await push(submissionsRef, submission);

    // Update student's last active date
    const studentRef = ref(database, 'students/' + submissionData.studentId);
    await update(studentRef, { lastActive: submission.submissionDate });

    elmApp.ports.submissionResult.send("Success: Submission saved successfully");
    console.log("Submission saved successfully");
  } catch (error) {
    console.error("Error saving submission:", error);
    elmApp.ports.submissionResult.send("Error: " + error.message);
  }
}

/**
 * Find a student record by name
 * @param {string} studentName - The name to search for
 * @param {Object} elmApp - The Elm application instance
 */
async function findStudentByName(studentName, elmApp) {
  try {
    // Format is firstname.lastname, which is not a valid Firebase path
    // We need to sanitize it for searching
    const sanitizedName = sanitizeFirebasePath(studentName);

    // Try direct lookup by sanitized name first (most efficient)
    const directRef = ref(database, `students/${sanitizedName}`);
    const directSnapshot = await get(directRef);

    if (directSnapshot.exists()) {
      // Found by direct lookup with sanitized name
      const studentData = directSnapshot.val();
      const foundStudent = {
        ...studentData,
        id: sanitizedName,
        submissions: []
      };

      // Now get this student's submissions
      const submissionsRef = ref(database, 'submissions');
      const submissionsSnapshot = await get(submissionsRef);

      if (submissionsSnapshot.exists()) {
        const submissionsData = submissionsSnapshot.val();
        const studentSubmissions = [];

        // Find all submissions for this student
        for (const submissionId in submissionsData) {
          const submission = submissionsData[submissionId];
          if (submission.studentId === foundStudent.id) {
            studentSubmissions.push({
              ...submission,
              id: submissionId
            });
          }
        }

        // Sort submissions by date (newest first)
        studentSubmissions.sort((a, b) => {
          return new Date(b.submissionDate) - new Date(a.submissionDate);
        });

        foundStudent.submissions = studentSubmissions;
      }

      // Send the student data back to Elm
      elmApp.ports.studentFound.send(foundStudent);
      return;
    }

    // If not found by direct lookup, try searching through all students
    // by checking the original name format in the name field
    const studentsRef = ref(database, 'students');
    const snapshot = await get(studentsRef);

    if (snapshot.exists()) {
      let foundStudent = null;
      const studentsData = snapshot.val();

      // Search through students for a match by the name field
      for (const studentId in studentsData) {
        const student = studentsData[studentId];
        if (student.name === studentName) {
          foundStudent = {
            ...student,
            id: studentId,
            submissions: []
          };
          break;
        }
      }

      if (foundStudent) {
        // Now get this student's submissions
        const submissionsRef = ref(database, 'submissions');
        const submissionsSnapshot = await get(submissionsRef);

        if (submissionsSnapshot.exists()) {
          const submissionsData = submissionsSnapshot.val();
          const studentSubmissions = [];

          // Find all submissions for this student
          for (const submissionId in submissionsData) {
            const submission = submissionsData[submissionId];
            if (submission.studentId === foundStudent.id) {
              studentSubmissions.push({
                ...submission,
                id: submissionId
              });
            }
          }

          // Sort submissions by date (newest first)
          studentSubmissions.sort((a, b) => {
            return new Date(b.submissionDate) - new Date(a.submissionDate);
          });

          foundStudent.submissions = studentSubmissions;
        }

        // Send the student data back to Elm
        elmApp.ports.studentFound.send(foundStudent);
      } else {
        // No student found
        elmApp.ports.studentFound.send(null);
      }
    } else {
      // No students in database
      elmApp.ports.studentFound.send(null);
    }
  } catch (error) {
    console.error("Error finding student:", error);
    elmApp.ports.studentFound.send(null);
  }
}

/**
 * Save or update a student record
 * @param {Object} studentData - The student data to save
 * @param {Object} elmApp - The Elm application instance
 */
async function saveStudentRecord(studentData, elmApp) {
  try {
    const studentId = studentData.id;
    const currentDate = new Date().toISOString().split('T')[0];

    // Update lastActive date
    const studentToSave = {
      ...studentData,
      lastActive: currentDate
    };

    // If there's no created date, add one
    if (!studentToSave.created) {
      studentToSave.created = currentDate;
    }

    // Remove submissions array from what we save to the database
    // (submissions are stored separately)
    delete studentToSave.submissions;

    // Save to Firebase
    await set(ref(database, 'students/' + studentId), studentToSave);

    // This will be handled by the submission result
    console.log("Student record saved successfully");
  } catch (error) {
    console.error("Error saving student:", error);
    elmApp.ports.submissionResult.send("Error: " + error.message);
  }
}

/**
 * Fetch all belts
 * @param {Object} elmApp - The Elm application instance
 */
async function fetchBelts(elmApp) {
  try {
    const beltsRef = ref(database, 'belts');
    const snapshot = await get(beltsRef);

    if (snapshot.exists()) {
      const beltsData = snapshot.val();
      const belts = [];

      // Convert Firebase object to array of belts with IDs
      for (const beltId in beltsData) {
        const belt = beltsData[beltId];
        belts.push({
          id: beltId,
          ...belt
        });
      }

      // Sort belts by order
      belts.sort((a, b) => a.order - b.order);

      // Send belts to Elm
      elmApp.ports.receiveBelts.send(belts);
    } else {
      // If no belts defined yet, create default belts
      const defaultBelts = [
        {
          id: "white-belt",
          name: "White Belt",
          color: "#FFFFFF",
          order: 1,
          gameOptions: ["Beginner Game 1", "Beginner Game 2", "Beginner Game 3"]
        },
        {
          id: "yellow-belt",
          name: "Yellow Belt",
          color: "#FFEB3B",
          order: 2,
          gameOptions: ["Intermediate Game A", "Intermediate Game B"]
        },
        {
          id: "green-belt",
          name: "Green Belt",
          color: "#4CAF50",
          order: 3,
          gameOptions: ["Advanced Game 1", "Advanced Game 2", "Advanced Game 3"]
        },
        {
          id: "black-belt",
          name: "Black Belt",
          color: "#212121",
          order: 4,
          gameOptions: ["Master Game X", "Master Game Y", "Master Game Z"]
        }
      ];

      // Save default belts to Firebase
      for (const belt of defaultBelts) {
        const beltId = belt.id;
        await set(ref(database, 'belts/' + beltId), belt);
      }

      // Send default belts to Elm
      elmApp.ports.receiveBelts.send(defaultBelts);
    }
  } catch (error) {
    console.error("Error fetching belts:", error);
    elmApp.ports.receiveBelts.send([]);
  }
}
