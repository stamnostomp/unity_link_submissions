// firebase-admin.js
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js';
import { getDatabase, ref, get, update, onValue, set, remove } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';
import {
  getAuth,
  signInWithEmailAndPassword,
  onAuthStateChanged,
  signOut,
  createUserWithEmailAndPassword,
  deleteUser
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
  // Handle authentication state changes
  onAuthStateChanged(auth, async (user) => {
    if (user) {
      try {
        // Get the admin data to include the role
        const adminRef = ref(database, `admins/${user.uid}`);
        const adminSnapshot = await get(adminRef);

        if (adminSnapshot.exists()) {
          const adminData = adminSnapshot.val();
          // User is signed in
          const userData = {
            uid: user.uid,
            email: user.email,
            displayName: user.displayName || user.email,
            role: adminData.role || "admin"  // Guarantee a default value
          };
          console.log("User is signed in:", userData);

          // If the admin doesn't have a role set, let's add one
          if (!adminData.role) {
            // Update the admin record with a default role
            await update(adminRef, { role: "admin" });
            console.log("Added default 'admin' role to existing admin user");
          }

          elmApp.ports.receiveAuthState.send({
            user: userData,
            isSignedIn: true
          });

          // Now that user is signed in, we can start listening for submissions
          setupAdminSubmissionListeners(elmApp);
        } else {
          // Admin record not found
          console.log("Admin record not found for authenticated user");
          elmApp.ports.receiveAuthState.send({
            user: null,
            isSignedIn: false
          });
        }
      } catch (error) {
        console.error("Error fetching admin data:", error);
        elmApp.ports.receiveAuthState.send({
          user: null,
          isSignedIn: false
        });
      }
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
          message: getAdminAuthErrorMessage(error.code)
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
      fetchAdminSubmissions(elmApp);
    } else {
      console.warn("Cannot fetch submissions: User not authenticated");
    }
  });

  elmApp.ports.saveGrade.subscribe(function(data) {
    if (auth.currentUser) {
      saveAdminGrade(data, elmApp);
    } else {
      console.warn("Cannot save grade: User not authenticated");
      elmApp.ports.gradeResult.send("Error: Not authenticated");
    }
  });

  // Handle student record requests
  elmApp.ports.requestStudentRecord.subscribe(function(studentId) {
    if (auth.currentUser) {
      fetchStudentRecord(studentId, elmApp);
    } else {
      console.warn("Cannot fetch student record: User not authenticated");
    }
  });

  // Handle student creation
  elmApp.ports.createStudent.subscribe(function(studentData) {
    if (auth.currentUser) {
      createNewStudentRecord(studentData, elmApp);
    } else {
      console.warn("Cannot create student: User not authenticated");
    }
  });

  // Belt management functionality
  elmApp.ports.requestBelts.subscribe(function() {
    if (auth.currentUser) {
      fetchBelts(elmApp);
    } else {
      console.warn("Cannot fetch belts: User not authenticated");
    }
  });

  elmApp.ports.saveBelt.subscribe(function(beltData) {
    if (auth.currentUser) {
      saveBelt(beltData, elmApp);
    } else {
      console.warn("Cannot save belt: User not authenticated");
      elmApp.ports.beltResult.send("Error: Not authenticated");
    }
  });

  elmApp.ports.deleteBelt.subscribe(function(beltId) {
    if (auth.currentUser) {
      deleteBelt(beltId, elmApp);
    } else {
      console.warn("Cannot delete belt: User not authenticated");
      elmApp.ports.beltResult.send("Error: Not authenticated");
    }
  });

  // Handle submission deletion requests
  elmApp.ports.deleteSubmission.subscribe(function(submissionId) {
    if (auth.currentUser) {
      deleteSubmissionRecord(submissionId, elmApp);
    } else {
      console.warn("Cannot delete submission: User not authenticated");
      elmApp.ports.submissionDeleted.send("Error: Not authenticated");
    }
  });

  // Handle student listing requests
  elmApp.ports.requestAllStudents.subscribe(function() {
    if (auth.currentUser) {
      fetchAllStudents(elmApp);
    } else {
      console.warn("Cannot fetch students: User not authenticated");
      elmApp.ports.receiveAllStudents.send([]);
    }
  });

  // Handle student deletion (including all submissions)
  elmApp.ports.deleteStudent.subscribe(function(studentId) {
    if (auth.currentUser) {
      deleteStudentAndSubmissions(studentId, elmApp);
    } else {
      console.warn("Cannot delete student: User not authenticated");
      elmApp.ports.studentDeleted.send("Error: Not authenticated");
    }
  });

  // Handle admin user creation requests
  if (elmApp.ports.createAdminUser) {
    elmApp.ports.createAdminUser.subscribe(function(userData) {
      if (auth.currentUser) {
        createAdminUserAccount(userData, elmApp);
      } else {
        console.warn("Cannot create admin user: User not authenticated");
        if (elmApp.ports.adminUserCreated) {
          elmApp.ports.adminUserCreated.send({
            success: false,
            message: "Not authenticated. Please sign in first."
          });
        }
      }
    });
  }

  // Admin user management
  if (elmApp.ports.requestAllAdmins) {
    elmApp.ports.requestAllAdmins.subscribe(function() {
      if (auth.currentUser) {
        fetchAllAdminUsers(elmApp);
      } else {
        console.warn("Cannot fetch admin users: User not authenticated");
        if (elmApp.ports.receiveAllAdmins) {
          elmApp.ports.receiveAllAdmins.send([]);
        }
      }
    });
  }

  if (elmApp.ports.updateAdminUser) {
    elmApp.ports.updateAdminUser.subscribe(function(adminUserData) {
      if (auth.currentUser) {
        updateAdminUserRecord(adminUserData, elmApp);
      } else {
        console.warn("Cannot update admin user: User not authenticated");
        if (elmApp.ports.adminUserUpdated) {
          elmApp.ports.adminUserUpdated.send({
            success: false,
            message: "Not authenticated. Please sign in first."
          });
        }
      }
    });
  }

  if (elmApp.ports.deleteAdminUser) {
    elmApp.ports.deleteAdminUser.subscribe(function(adminUserId) {
      if (auth.currentUser) {
        deleteAdminUserRecord(adminUserId, elmApp);
      } else {
        console.warn("Cannot delete admin user: User not authenticated");
        if (elmApp.ports.adminUserDeleted) {
          elmApp.ports.adminUserDeleted.send({
            success: false,
            message: "Not authenticated. Please sign in first."
          });
        }
      }
    });
  }

  // If logged in, check if we need to migrate role fields
  if (auth.currentUser) {
    migrateAdminRoles(elmApp);
  }
}

/**
 * Automatically migrate existing admin records to include role field
 * @param {Object} elmApp - The Elm application instance
 */
async function migrateAdminRoles(elmApp) {
  try {
    console.log("Checking for admin records missing role field...");
    const adminsRef = ref(database, 'admins');
    const adminsSnapshot = await get(adminsRef);

    if (adminsSnapshot.exists()) {
      const adminsData = adminsSnapshot.val();
      let migratedCount = 0;

      for (const uid in adminsData) {
        const admin = adminsData[uid];

        // If role is missing, add it
        if (!admin.role) {
          // For the first admin, make them a superuser
          const role = migratedCount === 0 ? "superuser" : "admin";

          await update(ref(database, `admins/${uid}`), { role });
          console.log(`Migrated admin ${admin.email} to role: ${role}`);
          migratedCount++;
        }
      }

      if (migratedCount > 0) {
        console.log(`Migrated ${migratedCount} admin records to include role field`);
      } else {
        console.log("All admin records already have role field");
      }
    }
  } catch (error) {
    console.error("Error migrating admin roles:", error);
  }
}

/**
 * Fetch all admin users from Firebase
 * @param {Object} elmApp - The Elm application instance
 */
async function fetchAllAdminUsers(elmApp) {
  try {
    // First check if the current user is an admin
    const currentUserUid = auth.currentUser.uid;
    const adminSnapshot = await get(ref(database, `admins/${currentUserUid}`));

    if (!adminSnapshot.exists()) {
      throw new Error("Only existing admins can manage admin accounts");
    }

    // Get all admin users
    const adminsRef = ref(database, 'admins');
    const adminsSnapshot = await get(adminsRef);

    if (adminsSnapshot.exists()) {
      const adminsData = adminsSnapshot.val();
      const adminUsers = [];

      for (const uid in adminsData) {
        const admin = adminsData[uid];
        adminUsers.push({
          uid,
          email: admin.email,
          displayName: admin.displayName || admin.email,
          role: admin.role || "admin",  // Ensure role has a default value
          createdBy: admin.createdBy || null,
          createdAt: admin.createdAt || null
        });
      }

      // Send the admin users to Elm
      elmApp.ports.receiveAllAdmins.send(adminUsers);
    } else {
      // No admin users found
      elmApp.ports.receiveAllAdmins.send([]);
    }
  } catch (error) {
    console.error("Error fetching admin users:", error);
    elmApp.ports.receiveAllAdmins.send([]);
  }
}

/**
 * Update an admin user record
 * @param {Object} adminUserData - The admin user data to update
 * @param {Object} elmApp - The Elm application instance
 */
// In firebase-admin.js, modify the updateAdminUserRecord function's permission checks:

async function updateAdminUserRecord(adminUserData, elmApp) {
  try {
    // First check if the current user is an admin
    const currentUserUid = auth.currentUser.uid;
    const adminSnapshot = await get(ref(database, `admins/${currentUserUid}`));

    if (!adminSnapshot.exists()) {
      throw new Error("Only existing admins can manage admin accounts");
    }

    // Get the current user's role
    const currentAdminData = adminSnapshot.val();
    const isCurrentUserSuperuser = currentAdminData.role === "superuser";

    // Make sure regular admins can't update superusers
    const targetAdminRef = ref(database, `admins/${adminUserData.uid}`);
    const targetAdminSnapshot = await get(targetAdminRef);

    if (targetAdminSnapshot.exists()) {
      const targetAdminData = targetAdminSnapshot.val();
      const isTargetSuperuser = targetAdminData.role === "superuser";

      // Check if a non-superuser is trying to update a superuser
      if (isTargetSuperuser && !isCurrentUserSuperuser) {
        throw new Error("Only superusers can modify other superuser accounts");
      }

      // Check if trying to promote to superuser without being a superuser
      if (adminUserData.role === "superuser" && !isCurrentUserSuperuser) {
        throw new Error("Only superusers can promote accounts to superuser status");
      }

      // IMPORTANT: There's no restriction on superusers downgrading other superusers to regular admins
      // This allows role changes in both directions
    }

    // Check if trying to update your own account
    if (adminUserData.uid === currentUserUid) {
      // Don't allow superusers to downgrade themselves (prevents lockout situation)
      if (isCurrentUserSuperuser && adminUserData.role !== "superuser") {
        throw new Error("You cannot downgrade your own superuser status");
      }

      // Allow updating display name but not email for current user
      // This is to prevent locking yourself out
      const adminRef = ref(database, `admins/${adminUserData.uid}`);
      await update(adminRef, {
        displayName: adminUserData.displayName,
        // Allow updating your own role if you're not downgrading from superuser
        role: adminUserData.role
      });

      elmApp.ports.adminUserUpdated.send({
        success: true,
        message: "Success: Your account information has been updated."
      });
      return;
    }

    // Ensure role is defined with a default value if it's missing
    const roleToUse = adminUserData.role || "admin";

    console.log("Updating admin user with role:", roleToUse);

    // Update the admin record
    await update(targetAdminRef, {
      email: adminUserData.email,
      displayName: adminUserData.displayName,
      role: roleToUse, // Use the role with fallback to "admin"
      updatedBy: auth.currentUser.email,
      updatedAt: new Date().toISOString()
    });

    // Return success
    elmApp.ports.adminUserUpdated.send({
      success: true,
      message: "Success: Admin user updated successfully"
    });
  } catch (error) {
    console.error("Error updating admin user:", error);
    elmApp.ports.adminUserUpdated.send({
      success: false,
      message: "Error: " + error.message
    });
  }
}

/**
 * Delete an admin user
 * @param {string} adminUserId - The admin user ID to delete
 * @param {Object} elmApp - The Elm application instance
 */
async function deleteAdminUserRecord(adminUserId, elmApp) {
  try {
    // First check if the current user is an admin
    const currentUserUid = auth.currentUser.uid;
    const adminSnapshot = await get(ref(database, `admins/${currentUserUid}`));

    if (!adminSnapshot.exists()) {
      throw new Error("Only existing admins can manage admin accounts");
    }

    // Get the current user's role
    const currentAdminData = adminSnapshot.val();
    const isCurrentUserSuperuser = currentAdminData.role === "superuser";

    // Check if trying to delete a superuser
    const targetAdminRef = ref(database, `admins/${adminUserId}`);
    const targetAdminSnapshot = await get(targetAdminRef);

    if (targetAdminSnapshot.exists()) {
      const targetAdminData = targetAdminSnapshot.val();
      if (targetAdminData.role === "superuser" && !isCurrentUserSuperuser) {
        throw new Error("Only superusers can delete other superuser accounts");
      }
    } else {
      throw new Error("Admin user not found");
    }

    // Check if trying to delete your own account
    if (adminUserId === currentUserUid) {
      throw new Error("You cannot delete your own admin account");
    }

    // Check how many admin users exist (to prevent deleting the last admin)
    const adminsRef = ref(database, 'admins');
    const adminsSnapshot = await get(adminsRef);

    if (!adminsSnapshot.exists() || Object.keys(adminsSnapshot.val()).length <= 1) {
      throw new Error("Cannot delete the only admin user");
    }

    // Delete the admin record
    await remove(targetAdminRef);

    // Return success
    elmApp.ports.adminUserDeleted.send({
      success: true,
      message: "Success: Admin user deleted successfully"
    });
  } catch (error) {
    console.error("Error deleting admin user:", error);
    elmApp.ports.adminUserDeleted.send({
      success: false,
      message: "Error: " + error.message
    });
  }
}

/**
 * Create a new admin user account
 * @param {Object} userData - The user data {email, password, displayName, role}
 * @param {Object} elmApp - The Elm application instance
 */
async function createAdminUserAccount(userData, elmApp) {
  try {
    const { email, password, displayName, role } = userData;

    // First check if the current user is an admin
    const currentUserUid = auth.currentUser.uid;
    const adminSnapshot = await get(ref(database, `admins/${currentUserUid}`));

    if (!adminSnapshot.exists()) {
      throw new Error("Only existing admins can create new admin accounts");
    }

    // Check if the current user is a superuser before allowing creation of another superuser
    const currentAdminData = adminSnapshot.val();
    const currentUserRole = currentAdminData.role || "admin";
    if (role === "superuser" && currentUserRole !== "superuser") {
      throw new Error("Only superusers can create other superuser accounts");
    }

    // Create the user with Firebase Auth
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    // Save admin record to database
    const adminRef = ref(database, `admins/${user.uid}`);
    await set(adminRef, {
      email: email,
      displayName: displayName || email,
      role: role || "admin",  // Use the provided role or default to "admin"
      createdBy: auth.currentUser.email,
      createdAt: new Date().toISOString()
    });

    // Return success to Elm
    if (elmApp.ports.adminUserCreated) {
      elmApp.ports.adminUserCreated.send({
        success: true,
        message: "Admin user created successfully"
      });
    }
  } catch (error) {
    console.error("Error creating admin user:", error);
    if (elmApp.ports.adminUserCreated) {
      elmApp.ports.adminUserCreated.send({
        success: false,
        message: error.message
      });
    }
  }
}

/**
 * Delete a student and all their submissions from Firebase
 * @param {string} studentId - The student ID to delete
 * @param {Object} elmApp - The Elm application instance
 */
async function deleteStudentAndSubmissions(studentId, elmApp) {
  try {
    // First fetch all submissions to find those belonging to this student
    const submissionsRef = ref(database, 'submissions');
    const submissionsSnapshot = await get(submissionsRef);

    const deletionPromises = [];

    // Delete all submissions for this student
    if (submissionsSnapshot.exists()) {
      const submissionsData = submissionsSnapshot.val();

      // Find all submissions for this student and delete them
      for (const submissionId in submissionsData) {
        const submission = submissionsData[submissionId];
        if (submission.studentId === studentId) {
          // Add to deletion promises
          const submissionRef = ref(database, `submissions/${submissionId}`);
          deletionPromises.push(remove(submissionRef));
          console.log(`Deleting submission: ${submissionId}`);
        }
      }
    }

    // Wait for all submission deletions to complete
    await Promise.all(deletionPromises);

    // Finally delete the student record
    const studentRef = ref(database, `students/${studentId}`);
    await remove(studentRef);

    // Send success message back to Elm
    elmApp.ports.studentDeleted.send(studentId);
    console.log(`Student ${studentId} and all their submissions deleted successfully`);
  } catch (error) {
    console.error("Error deleting student and submissions:", error);
    elmApp.ports.studentDeleted.send("Error: " + error.message);
  }
}

/**
 * Delete a submission from Firebase
 * @param {string} submissionId - The submission ID to delete
 * @param {Object} elmApp - The Elm application instance
 */
async function deleteSubmissionRecord(submissionId, elmApp) {
  try {
    const submissionRef = ref(database, `submissions/${submissionId}`);

    // First check if the submission exists
    const snapshot = await get(submissionRef);
    if (!snapshot.exists()) {
      throw new Error("Submission not found");
    }

    // Delete the submission
    await remove(submissionRef);

    // Send success message back to Elm
    elmApp.ports.submissionDeleted.send(submissionId);
    console.log("Submission deleted successfully");
  } catch (error) {
    console.error("Error deleting submission:", error);
    elmApp.ports.submissionDeleted.send("Error: " + error.message);
  }
}

/**
 * Fetch all students from Firebase
 * @param {Object} elmApp - The Elm application instance
 */
function fetchAllStudents(elmApp) {
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

        elmApp.ports.receiveAllStudents.send(students);
      } else {
        // Return empty array if no students
        elmApp.ports.receiveAllStudents.send([]);
      }
    })
    .catch((error) => {
      console.error("Error fetching students:", error);
      elmApp.ports.receiveAllStudents.send([]);
    });
}

/**
 * Fetch all belts from Firebase
 * @param {Object} elmApp - The Elm application instance
 */
function fetchBelts(elmApp) {
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

        elmApp.ports.receiveBelts.send(belts);
      } else {
        // Return empty array if no belts
        elmApp.ports.receiveBelts.send([]);
      }
    })
    .catch((error) => {
      console.error("Error fetching belts:", error);
      elmApp.ports.receiveBelts.send([]);
    });
}

/**
 * Save a belt to Firebase
 * @param {Object} beltData - The belt data to save
 * @param {Object} elmApp - The Elm application instance
 */
function saveBelt(beltData, elmApp) {
  const beltId = beltData.id;
  const beltRef = ref(database, `belts/${beltId}`);

  // Check if the belt already exists
  get(beltRef)
    .then((snapshot) => {
      const isNewBelt = !snapshot.exists();

      // Save the belt data
      set(beltRef, beltData)
        .then(() => {
          elmApp.ports.beltResult.send(isNewBelt ?
            "Success: Belt created successfully" :
            "Success: Belt updated successfully");
        })
        .catch((error) => {
          elmApp.ports.beltResult.send("Error: " + error.message);
          console.error("Error saving belt:", error);
        });
    })
    .catch((error) => {
      elmApp.ports.beltResult.send("Error: " + error.message);
      console.error("Error checking belt existence:", error);
    });
}

/**
 * Delete a belt from Firebase
 * @param {string} beltId - The belt ID to delete
 * @param {Object} elmApp - The Elm application instance
 */
function deleteBelt(beltId, elmApp) {
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
          elmApp.ports.beltResult.send("Error: Cannot delete. This belt is already in use by one or more submissions.");
          return;
        }
      }

      // If the belt is not in use, proceed with deletion
      remove(beltRef)
        .then(() => {
          elmApp.ports.beltResult.send("Success: Belt deleted successfully");
        })
        .catch((error) => {
          elmApp.ports.beltResult.send("Error: " + error.message);
          console.error("Error deleting belt:", error);
        });
    })
    .catch((error) => {
      elmApp.ports.beltResult.send("Error: " + error.message);
      console.error("Error checking belt usage:", error);
    });
}

/**
 * Fetch a student record and all their submissions
 * @param {string} studentId - The student ID to fetch
 * @param {Object} elmApp - The Elm application instance
 */
async function fetchStudentRecord(studentId, elmApp) {
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

    // Send the data back to Elm
    elmApp.ports.receiveStudentRecord.send({
      student,
      submissions: studentSubmissions
    });

  } catch (error) {
    console.error("Error fetching student record:", error);
    // In a real app, you'd want to send an error back to Elm
  }
}

/**
 * Set up listeners for submissions data after authentication
 * @param {Object} elmApp - The Elm application instance
 */
function setupAdminSubmissionListeners(elmApp) {
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
function fetchAdminSubmissions(elmApp) {
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
function saveAdminGrade(data, elmApp) {
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

/**
 * Create a new student record
 * @param {Object} studentData - The student data to create
 * @param {Object} elmApp - The Elm application instance
 */
async function createNewStudentRecord(studentData, elmApp) {
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
      elmApp.ports.studentCreated.send({
        id: uniqueId,
        ...studentRecord
      });
    } else {
      // Save the student record with the sanitized ID
      await set(studentRef, studentRecord);

      // Return the created student record with its ID
      elmApp.ports.studentCreated.send({
        id: studentId,
        ...studentRecord
      });
    }
  } catch (error) {
    console.error("Error creating student record:", error);
    // Send error back to Elm
    elmApp.ports.studentCreated.send({
      error: error.message || "Error creating student record"
    });
  }
}
