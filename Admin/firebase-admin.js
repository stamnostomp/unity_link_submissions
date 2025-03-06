// firebase-admin.js
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js';
import { getDatabase, ref, get, update, onValue, set, remove } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';
import {
  getAuth,
  signInWithEmailAndPassword,
  onAuthStateChanged,
  signOut
} from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js';

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

// Debug flag - set to true for detailed console logs
const DEBUG = true;

// Utility functions
function log(message, data) {
  if (DEBUG) {
    console.log(`[Firebase Admin] ${message}`, data || '');
  }
}

function logError(message, error) {
  console.error(`[Firebase Admin Error] ${message}`, error);
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
 * Validate that a name is in firstname.lastname format
 * @param {string} name - The name to validate
 * @return {boolean} True if valid format
 */
function isValidNameFormat(name) {
  const parts = name.split('.');
  return parts.length === 2 && parts[0].length > 0 && parts[1].length > 0;
}

/**
 * Initialize the Firebase integration with the Elm app
 * @param {Object} elmApp - The Elm application instance
 */
export function initializeFirebase(elmApp) {
  log('Initializing Firebase integration');

  // Handle authentication state changes
  onAuthStateChanged(auth, (user) => {
    if (user) {
      // User is signed in
      const userData = {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName || user.email,
      };
      log("User is signed in:", userData);
      elmApp.ports.receiveAuthState.send({
        user: userData,
        isSignedIn: true
      });

      // Now that user is signed in, we can start listening for submissions
      setupAdminSubmissionListeners(elmApp);
    } else {
      // User is signed out
      log("User is signed out");
      elmApp.ports.receiveAuthState.send({
        user: null,
        isSignedIn: false
      });
    }
  });

  // Auth Ports -----------------
  // Handle sign in requests from Elm
  elmApp.ports.signIn.subscribe(function(credentials) {
    log('Sign in request received');
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
        logError("Error signing in:", error);
        elmApp.ports.receiveAuthResult.send({
          success: false,
          message: getAdminAuthErrorMessage(error.code)
        });
      });
  });

  // Handle sign out requests from Elm
  elmApp.ports.signOut.subscribe(function() {
    log('Sign out request received');
    signOut(auth)
      .then(() => {
        // Successful sign-out is handled by onAuthStateChanged
      })
      .catch((error) => {
        logError("Error signing out:", error);
      });
  });

  // Submission Ports -----------------
  // Handle submission requests from Elm
  elmApp.ports.requestSubmissions.subscribe(function() {
    log('Request submissions received');
    if (auth.currentUser) {
      fetchAdminSubmissions(elmApp);
    } else {
      logError("Cannot fetch submissions: User not authenticated");
    }
  });

  // Handle grade submissions from Elm
  elmApp.ports.saveGrade.subscribe(function(data) {
    log('Save grade request received', data);
    if (auth.currentUser) {
      saveAdminGrade(data, elmApp);
    } else {
      logError("Cannot save grade: User not authenticated");
      elmApp.ports.gradeResult.send("Error: Not authenticated");
    }
  });

  // Student Record Ports -----------------
  // Handle student record requests
  elmApp.ports.requestStudentRecord.subscribe(function(studentId) {
    log('Request student record received', { studentId });
    if (auth.currentUser) {
      fetchStudentRecord(studentId, elmApp);
    } else {
      logError("Cannot fetch student record: User not authenticated");
    }
  });

  // Handle student creation
  elmApp.ports.createStudent.subscribe(function(studentData) {
    log('Create student request received', studentData);
    if (auth.currentUser) {
      createNewStudentRecord(studentData, elmApp);
    } else {
      logError("Cannot create student: User not authenticated");
    }
  });

  // Student Management Ports -----------------
  // Handle request for all students
  elmApp.ports.requestAllStudents.subscribe(function() {
    log('Request all students received');
    if (auth.currentUser) {
      fetchAllStudents(elmApp);
    } else {
      logError("Cannot fetch students: User not authenticated");
    }
  });

  // Handle student updates
  elmApp.ports.updateStudent.subscribe(function(studentData) {
    log('Update student request received', studentData);
    if (auth.currentUser) {
      updateStudentRecord(studentData, elmApp);
    } else {
      logError("Cannot update student: User not authenticated");
    }
  });

  // Handle student deletion
  elmApp.ports.deleteStudent.subscribe(function(studentId) {
    log('Delete student request received', { studentId });
    if (auth.currentUser) {
      deleteStudentRecord(studentId, elmApp);
    } else {
      logError("Cannot delete student: User not authenticated");
    }
  });

  // Belt Management Ports -----------------
  // Handle belt management
  elmApp.ports.requestBelts.subscribe(function() {
    log('Request belts received');
    if (auth.currentUser) {
      fetchBelts(elmApp);
    } else {
      logError("Cannot fetch belts: User not authenticated");
    }
  });

  elmApp.ports.saveBelt.subscribe(function(beltData) {
    log('Save belt request received', beltData);
    if (auth.currentUser) {
      saveBelt(beltData, elmApp);
    } else {
      logError("Cannot save belt: User not authenticated");
      elmApp.ports.beltResult.send("Error: Not authenticated");
    }
  });

  elmApp.ports.deleteBelt.subscribe(function(beltId) {
    log('Delete belt request received', { beltId });
    if (auth.currentUser) {
      deleteBelt(beltId, elmApp);
    } else {
      logError("Cannot delete belt: User not authenticated");
      elmApp.ports.beltResult.send("Error: Not authenticated");
    }
  });
}

/**
 * Fetch all students from Firebase
 * @param {Object} elmApp - The Elm application instance
 */
function fetchAllStudents(elmApp) {
  log('Fetching all students');
  const studentsRef = ref(database, 'students');

  get(studentsRef)
    .then((snapshot) => {
      if (snapshot.exists()) {
        const data = snapshot.val();
        // Convert Firebase object to array of students with IDs
        const students = Object.entries(data).map(([id, student]) => {
          return {
            id,
            ...student
          };
        });

        log(`Found ${students.length} students`);
        elmApp.ports.receiveAllStudents.send(students);
      } else {
        log('No students found');
        // Return empty array if no students
        elmApp.ports.receiveAllStudents.send([]);
      }
    })
    .catch((error) => {
      logError("Error fetching students:", error);
      elmApp.ports.receiveAllStudents.send([]);
    });
}

/**
 * Update a student record in Firebase
 * @param {Object} studentData - The student data to update
 * @param {Object} elmApp - The Elm application instance
 */
function updateStudentRecord(studentData, elmApp) {
  log('Updating student record', studentData);
  const studentId = studentData.id;
  const studentRef = ref(database, `students/${studentId}`);

  // Update only specific fields to preserve others
  get(studentRef)
    .then((snapshot) => {
      if (snapshot.exists()) {
        const existingData = snapshot.val();
        const updatedData = {
          ...existingData,
          name: studentData.name
        };

        update(studentRef, updatedData)
          .then(() => {
            // Return the updated student data
            const updatedStudent = {
              id: studentId,
              ...updatedData
            };
            log('Student updated successfully', updatedStudent);
            elmApp.ports.studentUpdated.send(updatedStudent);
          })
          .catch((error) => {
            logError("Error updating student record:", error);
            elmApp.ports.studentUpdated.send({
              error: error.message
            });
          });
      } else {
        logError("Student record not found for update");
        elmApp.ports.studentUpdated.send({
          error: "Student record not found"
        });
      }
    })
    .catch((error) => {
      logError("Error fetching student record for update:", error);
      elmApp.ports.studentUpdated.send({
        error: error.message
      });
    });
}

/**
 * Delete a student record from Firebase
 * @param {string} studentId - The student ID to delete
 * @param {Object} elmApp - The Elm application instance
 */
function deleteStudentRecord(studentId, elmApp) {
  log('Deleting student record', { studentId });
  // First check if the student has any submissions
  const submissionsRef = ref(database, 'submissions');

  get(submissionsRef)
    .then((snapshot) => {
      if (snapshot.exists()) {
        const submissions = snapshot.val();
        const hasSubmissions = Object.values(submissions).some(
          submission => submission.studentId === studentId
        );

        if (hasSubmissions) {
          const errorMsg = "Cannot delete student with existing submissions. Please delete the submissions first.";
          logError(errorMsg);
          elmApp.ports.studentDeleted.send({
            error: errorMsg
          });
          return;
        }
      }

      // If no submissions, proceed with deletion
      const studentRef = ref(database, `students/${studentId}`);

      remove(studentRef)
        .then(() => {
          log('Student deleted successfully', { studentId });
          elmApp.ports.studentDeleted.send(studentId);
        })
        .catch((error) => {
          logError("Error deleting student record:", error);
          elmApp.ports.studentDeleted.send({
            error: error.message
          });
        });
    })
    .catch((error) => {
      logError("Error checking student submissions:", error);
      elmApp.ports.studentDeleted.send({
        error: error.message
      });
    });
}

/**
 * Fetch all belts from Firebase
 * @param {Object} elmApp - The Elm application instance
 */
function fetchBelts(elmApp) {
  log('Fetching belts');
  const beltsRef = ref(database, 'belts');

  get(beltsRef)
    .then((snapshot) => {
      if (snapshot.exists()) {
        const data = snapshot.val();
        // Convert Firebase object to array of belts with IDs
        const belts = Object.entries(data).map(([id, belt]) => {
          return {
            id,
            ...belt
          };
        });

        log(`Found ${belts.length} belts`);
        elmApp.ports.receiveBelts.send(belts);
      } else {
        log('No belts found');
        // Return empty array if no belts
        elmApp.ports.receiveBelts.send([]);
      }
    })
    .catch((error) => {
      logError("Error fetching belts:", error);
      elmApp.ports.receiveBelts.send([]);
    });
}

/**
 * Save a belt to Firebase
 * @param {Object} beltData - The belt data to save
 * @param {Object} elmApp - The Elm application instance
 */
function saveBelt(beltData, elmApp) {
  log('Saving belt', beltData);
  const beltId = beltData.id;
  const beltRef = ref(database, `belts/${beltId}`);

  // Check if the belt already exists
  get(beltRef)
    .then((snapshot) => {
      const isNewBelt = !snapshot.exists();

      // Save the belt data
      set(beltRef, beltData)
        .then(() => {
          const resultMsg = isNewBelt ?
            "Success: Belt created successfully" :
            "Success: Belt updated successfully";
          log(resultMsg);
          elmApp.ports.beltResult.send(resultMsg);
        })
        .catch((error) => {
          const errorMsg = "Error: " + error.message;
          logError("Error saving belt:", error);
          elmApp.ports.beltResult.send(errorMsg);
        });
    })
    .catch((error) => {
      const errorMsg = "Error: " + error.message;
      logError("Error checking belt existence:", error);
      elmApp.ports.beltResult.send(errorMsg);
    });
}

/**
 * Delete a belt from Firebase
 * @param {string} beltId - The belt ID to delete
 * @param {Object} elmApp - The Elm application instance
 */
function deleteBelt(beltId, elmApp) {
  log('Deleting belt', { beltId });
  const beltRef = ref(database, `belts/${beltId}`);

  // First check if the belt is being used in any submissions
  const submissionsRef = ref(database, 'submissions');
  get(submissionsRef)
    .then((snapshot) => {
      if (snapshot.exists()) {
        const submissions = snapshot.val();
        const isUsed = Object.values(submissions).some(
          submission => submission.beltLevel === beltId
        );

        if (isUsed) {
          const errorMsg = "Error: Cannot delete. This belt is already in use by one or more submissions.";
          logError(errorMsg);
          elmApp.ports.beltResult.send(errorMsg);
          return;
        }
      }

      // If the belt is not in use, proceed with deletion
      remove(beltRef)
        .then(() => {
          log('Belt deleted successfully', { beltId });
          elmApp.ports.beltResult.send("Success: Belt deleted successfully");
        })
        .catch((error) => {
          const errorMsg = "Error: " + error.message;
          logError("Error deleting belt:", error);
          elmApp.ports.beltResult.send(errorMsg);
        });
    })
    .catch((error) => {
      const errorMsg = "Error: " + error.message;
      logError("Error checking belt usage:", error);
      elmApp.ports.beltResult.send(errorMsg);
    });
}

/**
 * Fetch a student record and all their submissions
 * @param {string} studentId - The student ID to fetch
 * @param {Object} elmApp - The Elm application instance
 */
async function fetchStudentRecord(studentId, elmApp) {
  log('Fetching student record', { studentId });
  try {
    // Fetch the student record
    const studentRef = ref(database, `students/${studentId}`);
    const studentSnapshot = await get(studentRef);

    if (!studentSnapshot.exists()) {
      throw new Error("Student record not found");
    }

    const student = {
      id: studentId,
      ...studentSnapshot.val()
    };

    // Fetch all submissions for this student
    const submissionsRef = ref(database, 'submissions');
    const submissionsSnapshot = await get(submissionsRef);

    const studentSubmissions = [];

    if (submissionsSnapshot.exists()) {
      const submissionsData = submissionsSnapshot.val();

      // Find all submissions for this student
      for (const submissionId in submissionsData) {
        const submission = submissionsData[submissionId];
        if (submission.studentId === studentId) {
          studentSubmissions.push({
            id: submissionId,
            ...submission
          });
        }
      }

      // Sort submissions by date (newest first)
      studentSubmissions.sort((a, b) => {
        return new Date(b.submissionDate) - new Date(a.submissionDate);
      });
    }

    log(`Found student with ${studentSubmissions.length} submissions`);

    // Send the data back to Elm
    elmApp.ports.receiveStudentRecord.send({
      student,
      submissions: studentSubmissions
    });

  } catch (error) {
    logError("Error fetching student record:", error);
    // In a real app, you'd want to send an error back to Elm
    elmApp.ports.receiveStudentRecord.send({
      error: error.message || "Error fetching student record"
    });
  }
}

/**
 * Set up listeners for submissions data after authentication
 * @param {Object} elmApp - The Elm application instance
 */
function setupAdminSubmissionListeners(elmApp) {
  log('Setting up submission listeners');
  // Initial fetch
  fetchAdminSubmissions(elmApp);

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

      log(`Received ${submissions.length} submissions from real-time update`);
      elmApp.ports.receiveSubmissions.send(submissions);
    } else {
      log('No submissions in real-time update');
      elmApp.ports.receiveSubmissions.send([]);
    }
  });
}

/**
 * Fetch all submissions from Firebase
 * @param {Object} elmApp - The Elm application instance
 */
function fetchAdminSubmissions(elmApp) {
  log('Fetching submissions');
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

        log(`Found ${submissions.length} submissions`);
        elmApp.ports.receiveSubmissions.send(submissions);
      } else {
        log('No submissions found');
        // Return empty array if no submissions
        elmApp.ports.receiveSubmissions.send([]);
      }
    })
    .catch((error) => {
      logError("Error fetching submissions:", error);
      elmApp.ports.receiveSubmissions.send([]);
    });
}

/**
 * Save a grade to Firebase
 * @param {Object} data - The grade data to save
 * @param {Object} elmApp - The Elm application instance
 */
function saveAdminGrade(data, elmApp) {
  log('Saving grade', data);
  const submissionId = data.submissionId;
  const grade = data.grade;

  // Add the current user's email to the grade
  grade.gradedBy = auth.currentUser.email;

  // Add the current date as the grading date
  grade.gradingDate = new Date().toISOString().split('T')[0];

  const submissionRef = ref(database, `submissions/${submissionId}`);

  // Update the grade for the submission
  update(submissionRef, { grade })
    .then(() => {
      log('Grade saved successfully');
      elmApp.ports.gradeResult.send("Success: Grade saved successfully");
    })
    .catch((error) => {
      const errorMsg = "Error: " + error.message;
      logError("Error saving grade:", error);
      elmApp.ports.gradeResult.send(errorMsg);
    });
}

/**
 * Create a new student record
 * @param {Object} studentData - The student data to create
 * @param {Object} elmApp - The Elm application instance
 */
async function createNewStudentRecord(studentData, elmApp) {
  log('Creating new student record', studentData);
  try {
    const { name } = studentData;

    // Validate name format
    if (!name || !isValidNameFormat(name)) {
      throw new Error("Student name must be in firstname.lastname format");
    }

    // Use the name as the base for the ID but sanitize it for Firebase
    // Convert dots to underscores for Firebase path compatibility
    const studentId = sanitizeFirebasePath(name);
    const currentDate = new Date().toISOString().split('T')[0];

    // Create the student record - keep the original name format for display
    const studentRecord = {
      name: name,  // Keep the original name with dots for display
      created: currentDate,
      lastActive: currentDate
    };

    // Check if student with this ID already exists
    const studentRef = ref(database, `students/${studentId}`);
    const snapshot = await get(studentRef);

    if (snapshot.exists()) {
      // If exists, generate a unique ID by adding a timestamp
      const timestamp = Date.now();
      const uniqueId = `${studentId}_${timestamp}`;
      const uniqueRef = ref(database, `students/${uniqueId}`);

      await set(uniqueRef, studentRecord);

      // Return the created student record with its ID
      const createdStudent = {
        id: uniqueId,
        ...studentRecord
      };

      log('Student created with timestamp-based ID', createdStudent);
      elmApp.ports.studentCreated.send(createdStudent);
    } else {
      // Save the student record with the sanitized ID
      await set(studentRef, studentRecord);

      // Return the created student record with its ID
      const createdStudent = {
        id: studentId,
        ...studentRecord
      };

      log('Student created with normal ID', createdStudent);
      elmApp.ports.studentCreated.send(createdStudent);
    }
  } catch (error) {
    logError("Error creating student record:", error);
    // Send error back to Elm
    elmApp.ports.studentCreated.send({
      error: error.message || "Error creating student record"
    });
  }
}

/**
 * Get a user-friendly error message for authentication errors
 * @param {string} errorCode - The Firebase error code
 * @return {string} A user-friendly error message
 */
function getAdminAuthErrorMessage(errorCode) {
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
