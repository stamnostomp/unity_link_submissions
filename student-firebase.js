// student-firebase.js
// Import Firebase modules using CDN URLs
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js';
import { getDatabase, ref, get, set, update, query, orderByChild, equalTo } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';

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
  // Listen for student search requests
  elmApp.ports.findStudent.subscribe(function(studentName) {
    findStudentByName(studentName, elmApp);
  });

  // Listen for student save requests
  elmApp.ports.saveStudent.subscribe(function(studentData) {
    saveStudentRecord(studentData, elmApp);
  });

  // Listen for submission save requests
  elmApp.ports.saveSubmission.subscribe(function(submissionData) {
    saveSubmissionRecord(submissionData, elmApp);
  });
}

/**
 * Find a student record by name
 * @param {string} studentName - The name to search for
 * @param {Object} elmApp - The Elm application instance
 */
async function findStudentByName(studentName, elmApp) {
  try {
    // First try exact match on normalized name
    const normalizedName = studentName.trim().toLowerCase();
    const studentsRef = ref(database, 'students');
    const snapshot = await get(studentsRef);

    if (snapshot.exists()) {
      let foundStudent = null;
      const studentsData = snapshot.val();

      // Search through students for a case-insensitive match
      for (const studentId in studentsData) {
        const student = studentsData[studentId];
        if (student.name.toLowerCase() === normalizedName) {
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
 * Save a submission record
 * @param {Object} submissionData - The submission data to save
 * @param {Object} elmApp - The Elm application instance
 */
async function saveSubmissionRecord(submissionData, elmApp) {
  try {
    const submissionId = submissionData.id;
    const currentDate = new Date().toISOString().split('T')[0];

    // Ensure submission date is set
    const submissionToSave = {
      ...submissionData,
      submissionDate: currentDate
    };

    // Save to Firebase
    await set(ref(database, 'submissions/' + submissionId), submissionToSave);

    // Also update the student's lastActive date
    const studentRef = ref(database, 'students/' + submissionData.studentId);
    await update(studentRef, { lastActive: currentDate });

    // Send success message back to Elm
    elmApp.ports.submissionResult.send("Success: Submission saved successfully");
    console.log("Submission saved successfully");
  } catch (error) {
    console.error("Error saving submission:", error);
    elmApp.ports.submissionResult.send("Error: " + error.message);
  }
}
