// firebase-admin.js
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js';
import { getDatabase, ref, get, update, onValue, set, remove, push } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';
import {
  getAuth,
  signInWithEmailAndPassword,
  onAuthStateChanged,
  signOut,
  createUserWithEmailAndPassword,
  deleteUser,
  sendPasswordResetEmail
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
 * Get current user helper function
 * @return {Object} Current user object
 */
function getCurrentUser() {
  return auth.currentUser || { email: 'unknown@example.com' };
}

/**
 * Initialize the Firebase integration with the Elm app
 * @param {Object} elmApp - The Elm application instance
 */
export function initializeFirebase(elmApp) {
  // Handle authentication state changes
  if (elmApp.ports && elmApp.ports.requestPasswordReset) {
    elmApp.ports.requestPasswordReset.subscribe(function(email) {
      console.log("Attempting to send password reset email to:", email);

      sendPasswordResetEmail(auth, email)
        .then(() => {
          console.log("Password reset email sent successfully!");
          if (elmApp.ports.passwordResetResult) {
            elmApp.ports.passwordResetResult.send({
              success: true,
              message: "Password reset email sent! Check your inbox."
            });
          }
        })
        .catch((error) => {
          console.error("Error sending password reset email:", error);
          if (elmApp.ports.passwordResetResult) {
            elmApp.ports.passwordResetResult.send({
              success: false,
              message: getPasswordResetErrorMessage(error.code)
            });
          }
        });
    });
  }

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
            role: adminData.role || "admin"
          };
          console.log("User is signed in:", userData);

          if (!adminData.role) {
            await update(adminRef, { role: "admin" });
            console.log("Added default 'admin' role to existing admin user");
          }

          elmApp.ports.receiveAuthState.send({
            user: userData,
            isSignedIn: true
          });

          setupAdminSubmissionListeners(elmApp);
        } else {
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

  // Submissions functionality
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

  // Student management functionality
  elmApp.ports.requestStudentRecord.subscribe(function(studentId) {
    if (auth.currentUser) {
      fetchStudentRecord(studentId, elmApp);
    } else {
      console.warn("Cannot fetch student record: User not authenticated");
    }
  });

  elmApp.ports.createStudent.subscribe(function(studentData) {
    if (auth.currentUser) {
      createNewStudentRecord(studentData, elmApp);
    } else {
      console.warn("Cannot create student: User not authenticated");
    }
  });

  elmApp.ports.requestAllStudents.subscribe(function() {
    if (auth.currentUser) {
      fetchAllStudents(elmApp);
    } else {
      console.warn("Cannot fetch students: User not authenticated");
      elmApp.ports.receiveAllStudents.send([]);
    }
  });

  elmApp.ports.deleteStudent.subscribe(function(studentId) {
    if (auth.currentUser) {
      deleteStudentAndSubmissions(studentId, elmApp);
    } else {
      console.warn("Cannot delete student: User not authenticated");
      elmApp.ports.studentDeleted.send("Error: Not authenticated");
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

  // Submission deletion
  elmApp.ports.deleteSubmission.subscribe(function(submissionId) {
    if (auth.currentUser) {
      deleteSubmissionRecord(submissionId, elmApp);
    } else {
      console.warn("Cannot delete submission: User not authenticated");
      elmApp.ports.submissionDeleted.send("Error: Not authenticated");
    }
  });

  // Admin user management
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

  // POINT MANAGEMENT SYSTEM - Add these port listeners
  if (elmApp.ports.requestStudentPoints) {
    elmApp.ports.requestStudentPoints.subscribe(function() {
      if (auth.currentUser) {
        requestStudentPoints(elmApp);
      } else {
        console.warn("Cannot fetch student points: User not authenticated");
        elmApp.ports.receiveStudentPoints.send([]);
      }
    });
  }

  if (elmApp.ports.awardPoints) {
    elmApp.ports.awardPoints.subscribe(function(data) {
      if (auth.currentUser) {
        awardPoints(data, elmApp);
      } else {
        console.warn("Cannot award points: User not authenticated");
        elmApp.ports.pointsAwarded.send({
          success: false,
          message: "Not authenticated. Please sign in first."
        });
      }
    });
  }

  if (elmApp.ports.requestPointRedemptions) {
    elmApp.ports.requestPointRedemptions.subscribe(function() {
      if (auth.currentUser) {
        requestPointRedemptions(elmApp);
      } else {
        console.warn("Cannot fetch redemptions: User not authenticated");
        elmApp.ports.receivePointRedemptions.send([]);
      }
    });
  }

  if (elmApp.ports.processRedemption) {
    elmApp.ports.processRedemption.subscribe(function(data) {
      if (auth.currentUser) {
        processRedemption(data, elmApp);
      } else {
        console.warn("Cannot process redemption: User not authenticated");
        elmApp.ports.redemptionProcessed.send({
          success: false,
          message: "Not authenticated. Please sign in first."
        });
      }
    });
  }

  if (elmApp.ports.requestPointRewards) {
    elmApp.ports.requestPointRewards.subscribe(function() {
      if (auth.currentUser) {
        requestPointRewards(elmApp);
      } else {
        console.warn("Cannot fetch rewards: User not authenticated");
        elmApp.ports.receivePointRewards.send([]);
      }
    });
  }

  if (elmApp.ports.savePointReward) {
    elmApp.ports.savePointReward.subscribe(function(rewardData) {
      if (auth.currentUser) {
        savePointReward(rewardData, elmApp);
      } else {
        console.warn("Cannot save reward: User not authenticated");
        elmApp.ports.pointRewardResult.send("Error: Not authenticated");
      }
    });
  }

  // If logged in, check if we need to migrate role fields
  if (auth.currentUser) {
    migrateAdminRoles(elmApp);
  }
}

// POINT MANAGEMENT FUNCTIONS

/**
 * Request student points data
 * @param {Object} elmApp - The Elm application instance
 */
function requestStudentPoints(elmApp) {
  const pointsRef = ref(database, 'studentPoints');

  get(pointsRef).then((snapshot) => {
    const pointsData = [];
    if (snapshot.exists()) {
      const data = snapshot.val();
      Object.keys(data).forEach(studentId => {
        pointsData.push({
          studentId: studentId,
          ...data[studentId]
        });
      });
    }
    elmApp.ports.receiveStudentPoints.send(pointsData);
  }).catch((error) => {
    console.error("Error fetching student points:", error);
    elmApp.ports.receiveStudentPoints.send([]);
  });
}

/**
 * Award points to a student
 * @param {Object} data - The points data {studentId, points, reason}
 * @param {Object} elmApp - The Elm application instance
 */
function awardPoints(data, elmApp) {
  const pointsRef = ref(database, `studentPoints/${data.studentId}`);

  get(pointsRef).then((snapshot) => {
    let currentData = {
      currentPoints: 0,
      totalEarned: 0,
      totalRedeemed: 0
    };

    if (snapshot.exists()) {
      currentData = snapshot.val();
    }

    const updatedData = {
      ...currentData,
      currentPoints: currentData.currentPoints + data.points,
      totalEarned: currentData.totalEarned + data.points,
      lastUpdated: new Date().toISOString()
    };

    return set(pointsRef, updatedData);
  }).then(() => {
    // Log the point award
    const historyRef = ref(database, 'pointHistory');
    const newHistoryRef = push(historyRef);
    return set(newHistoryRef, {
      studentId: data.studentId,
      points: data.points,
      reason: data.reason,
      awardedBy: getCurrentUser().email,
      awardedAt: new Date().toISOString(),
      type: 'awarded'
    });
  }).then(() => {
    elmApp.ports.pointsAwarded.send({
      success: true,
      message: `Successfully awarded ${data.points} points`
    });
  }).catch((error) => {
    console.error("Error awarding points:", error);
    elmApp.ports.pointsAwarded.send({
      success: false,
      message: "Error awarding points: " + error.message
    });
  });
}

/**
 * Request point redemptions data
 * @param {Object} elmApp - The Elm application instance
 */
function requestPointRedemptions(elmApp) {
  const redemptionsRef = ref(database, 'pointRedemptions');

  get(redemptionsRef).then((snapshot) => {
    const redemptions = [];
    if (snapshot.exists()) {
      const data = snapshot.val();
      Object.keys(data).forEach(id => {
        redemptions.push({
          id: id,
          ...data[id]
        });
      });
    }
    elmApp.ports.receivePointRedemptions.send(redemptions);
  }).catch((error) => {
    console.error("Error fetching redemptions:", error);
    elmApp.ports.receivePointRedemptions.send([]);
  });
}

/**
 * Process a point redemption
 * @param {Object} data - The redemption data {redemptionId, status, processedBy}
 * @param {Object} elmApp - The Elm application instance
 */
function processRedemption(data, elmApp) {
  const redemptionRef = ref(database, `pointRedemptions/${data.redemptionId}`);

  get(redemptionRef).then((snapshot) => {
    if (!snapshot.exists()) {
      throw new Error("Redemption not found");
    }

    const redemption = snapshot.val();
    const updates = {
      status: data.status,
      processedBy: data.processedBy,
      processedAt: new Date().toISOString()
    };

    return update(redemptionRef, updates);
  }).then(() => {
    elmApp.ports.redemptionProcessed.send({
      success: true,
      message: `Redemption ${data.status} successfully`
    });
  }).catch((error) => {
    console.error("Error processing redemption:", error);
    elmApp.ports.redemptionProcessed.send({
      success: false,
      message: "Error processing redemption: " + error.message
    });
  });
}

/**
 * Request point rewards data
 * @param {Object} elmApp - The Elm application instance
 */
function requestPointRewards(elmApp) {
  const rewardsRef = ref(database, 'pointRewards');

  get(rewardsRef).then((snapshot) => {
    const rewards = [];
    if (snapshot.exists()) {
      const data = snapshot.val();
      Object.keys(data).forEach(id => {
        rewards.push({
          id: id,
          ...data[id]
        });
      });
    }
    elmApp.ports.receivePointRewards.send(rewards);
  }).catch((error) => {
    console.error("Error fetching rewards:", error);
    elmApp.ports.receivePointRewards.send([]);
  });
}

/**
 * Save a point reward
 * @param {Object} rewardData - The reward data to save
 * @param {Object} elmApp - The Elm application instance
 */
function savePointReward(rewardData, elmApp) {
  const rewardsRef = ref(database, 'pointRewards');

  let rewardRef;
  if (rewardData.id && rewardData.id !== "") {
    // Update existing reward
    rewardRef = ref(database, `pointRewards/${rewardData.id}`);
  } else {
    // Create new reward
    rewardRef = push(rewardsRef);
  }

  const rewardToSave = {
    ...rewardData,
    updatedAt: new Date().toISOString()
  };

  if (!rewardData.id || rewardData.id === "") {
    rewardToSave.createdAt = new Date().toISOString();
  }

  set(rewardRef, rewardToSave).then(() => {
    elmApp.ports.pointRewardResult.send("Reward saved successfully");
  }).catch((error) => {
    console.error("Error saving reward:", error);
    elmApp.ports.pointRewardResult.send("Error: " + error.message);
  });
}

// ALL OTHER EXISTING FUNCTIONS REMAIN THE SAME...

/**
 * Automatically migrate existing admin records to include role field
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

        if (!admin.role) {
          const role = migratedCount === 0 ? "superuser" : "admin";
          await update(ref(database, `admins/${uid}`), { role });
          console.log(`Migrated admin ${admin.email} to role: ${role}`);
          migratedCount++;
        }
      }

      if (migratedCount > 0) {
        console.log(`Migrated ${migratedCount} admin records to include role field`);
      }
    }
  } catch (error) {
    console.error("Error migrating admin roles:", error);
  }
}

async function fetchAllAdminUsers(elmApp) {
  try {
    const currentUserUid = auth.currentUser.uid;
    const adminSnapshot = await get(ref(database, `admins/${currentUserUid}`));

    if (!adminSnapshot.exists()) {
      throw new Error("Only existing admins can manage admin accounts");
    }

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
          role: admin.role || "admin",
          createdBy: admin.createdBy || null,
          createdAt: admin.createdAt || null
        });
      }

      elmApp.ports.receiveAllAdmins.send(adminUsers);
    } else {
      elmApp.ports.receiveAllAdmins.send([]);
    }
  } catch (error) {
    console.error("Error fetching admin users:", error);
    elmApp.ports.receiveAllAdmins.send([]);
  }
}

async function updateAdminUserRecord(adminUserData, elmApp) {
  try {
    const currentUserUid = auth.currentUser.uid;
    const adminSnapshot = await get(ref(database, `admins/${currentUserUid}`));

    if (!adminSnapshot.exists()) {
      throw new Error("Only existing admins can manage admin accounts");
    }

    const currentAdminData = adminSnapshot.val();
    const isCurrentUserSuperuser = currentAdminData.role === "superuser";

    const targetAdminRef = ref(database, `admins/${adminUserData.uid}`);
    const targetAdminSnapshot = await get(targetAdminRef);

    if (targetAdminSnapshot.exists()) {
      const targetAdminData = targetAdminSnapshot.val();
      const isTargetSuperuser = targetAdminData.role === "superuser";

      if (isTargetSuperuser && !isCurrentUserSuperuser) {
        throw new Error("Only superusers can modify other superuser accounts");
      }

      if (adminUserData.role === "superuser" && !isCurrentUserSuperuser) {
        throw new Error("Only superusers can promote accounts to superuser status");
      }
    }

    if (adminUserData.uid === currentUserUid) {
      if (isCurrentUserSuperuser && adminUserData.role !== "superuser") {
        throw new Error("You cannot downgrade your own superuser status");
      }

      const adminRef = ref(database, `admins/${adminUserData.uid}`);
      await update(adminRef, {
        displayName: adminUserData.displayName,
        role: adminUserData.role
      });

      elmApp.ports.adminUserUpdated.send({
        success: true,
        message: "Success: Your account information has been updated."
      });
      return;
    }

    const roleToUse = adminUserData.role || "admin";

    await update(targetAdminRef, {
      email: adminUserData.email,
      displayName: adminUserData.displayName,
      role: roleToUse,
      updatedBy: auth.currentUser.email,
      updatedAt: new Date().toISOString()
    });

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

async function deleteAdminUserRecord(adminUserId, elmApp) {
  try {
    const currentUserUid = auth.currentUser.uid;
    const adminSnapshot = await get(ref(database, `admins/${currentUserUid}`));

    if (!adminSnapshot.exists()) {
      throw new Error("Only existing admins can manage admin accounts");
    }

    const currentAdminData = adminSnapshot.val();
    const isCurrentUserSuperuser = currentAdminData.role === "superuser";

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

    if (adminUserId === currentUserUid) {
      throw new Error("You cannot delete your own admin account");
    }

    const adminsRef = ref(database, 'admins');
    const adminsSnapshot = await get(adminsRef);

    if (!adminsSnapshot.exists() || Object.keys(adminsSnapshot.val()).length <= 1) {
      throw new Error("Cannot delete the only admin user");
    }

    await remove(targetAdminRef);

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

async function createAdminUserAccount(userData, elmApp) {
  try {
    const { email, password, displayName, role } = userData;

    const currentUserUid = auth.currentUser.uid;
    const adminSnapshot = await get(ref(database, `admins/${currentUserUid}`));

    if (!adminSnapshot.exists()) {
      throw new Error("Only existing admins can create new admin accounts");
    }

    const currentAdminData = adminSnapshot.val();
    const currentUserRole = currentAdminData.role || "admin";
    if (role === "superuser" && currentUserRole !== "superuser") {
      throw new Error("Only superusers can create other superuser accounts");
    }

    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    const adminRef = ref(database, `admins/${user.uid}`);
    await set(adminRef, {
      email: email,
      displayName: displayName || email,
      role: role || "admin",
      createdBy: auth.currentUser.email,
      createdAt: new Date().toISOString()
    });

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

async function deleteStudentAndSubmissions(studentId, elmApp) {
  try {
    const submissionsRef = ref(database, 'submissions');
    const submissionsSnapshot = await get(submissionsRef);

    const deletionPromises = [];

    if (submissionsSnapshot.exists()) {
      const submissionsData = submissionsSnapshot.val();

      for (const submissionId in submissionsData) {
        const submission = submissionsData[submissionId];
        if (submission.studentId === studentId) {
          const submissionRef = ref(database, `submissions/${submissionId}`);
          deletionPromises.push(remove(submissionRef));
          console.log(`Deleting submission: ${submissionId}`);
        }
      }
    }

    await Promise.all(deletionPromises);

    const studentRef = ref(database, `students/${studentId}`);
    await remove(studentRef);

    elmApp.ports.studentDeleted.send(studentId);
    console.log(`Student ${studentId} and all their submissions deleted successfully`);
  } catch (error) {
    console.error("Error deleting student and submissions:", error);
    elmApp.ports.studentDeleted.send("Error: " + error.message);
  }
}

async function deleteSubmissionRecord(submissionId, elmApp) {
  try {
    const submissionRef = ref(database, `submissions/${submissionId}`);

    const snapshot = await get(submissionRef);
    if (!snapshot.exists()) {
      throw new Error("Submission not found");
    }

    await remove(submissionRef);

    elmApp.ports.submissionDeleted.send(submissionId);
    console.log("Submission deleted successfully");
  } catch (error) {
    console.error("Error deleting submission:", error);
    elmApp.ports.submissionDeleted.send("Error: " + error.message);
  }
}

function fetchAllStudents(elmApp) {
  const studentsRef = ref(database, 'students');

  get(studentsRef)
    .then((snapshot) => {
      if (snapshot.exists()) {
        const data = snapshot.val();
        const students = Object.entries(data).map(([id, student]) => {
          return {
            id,
            ...student
          };
        });

        elmApp.ports.receiveAllStudents.send(students);
      } else {
        elmApp.ports.receiveAllStudents.send([]);
      }
    })
    .catch((error) => {
      console.error("Error fetching students:", error);
      elmApp.ports.receiveAllStudents.send([]);
    });
}

function fetchBelts(elmApp) {
  const beltsRef = ref(database, 'belts');

  get(beltsRef)
    .then((snapshot) => {
      if (snapshot.exists()) {
        const data = snapshot.val();
        const belts = Object.entries(data).map(([id, belt]) => {
          return {
            id,
            ...belt
          };
        });

        elmApp.ports.receiveBelts.send(belts);
      } else {
        elmApp.ports.receiveBelts.send([]);
      }
    })
    .catch((error) => {
      console.error("Error fetching belts:", error);
      elmApp.ports.receiveBelts.send([]);
    });
}

function saveBelt(beltData, elmApp) {
  const beltId = beltData.id;
  const beltRef = ref(database, `belts/${beltId}`);

  get(beltRef)
    .then((snapshot) => {
      const isNewBelt = !snapshot.exists();

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

function deleteBelt(beltId, elmApp) {
  const beltRef = ref(database, `belts/${beltId}`);

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

async function fetchStudentRecord(studentId, elmApp) {
  try {
    const studentRef = ref(database, `students/${studentId}`);
    const studentSnapshot = await get(studentRef);

    if (!studentSnapshot.exists()) {
      throw new Error("Student record not found");
    }

    const student = {
      id: studentId,
      ...studentSnapshot.val()
    };

    const submissionsRef = ref(database, 'submissions');
    const submissionsSnapshot = await get(submissionsRef);

    const studentSubmissions = [];

    if (submissionsSnapshot.exists()) {
      const submissionsData = submissionsSnapshot.val();

      for (const submissionId in submissionsData) {
        const submission = submissionsData[submissionId];
        if (submission.studentId === studentId) {
          studentSubmissions.push({
            id: submissionId,
            ...submission
          });
        }
      }

      studentSubmissions.sort((a, b) => {
        return new Date(b.submissionDate) - new Date(a.submissionDate);
      });
    }

    elmApp.ports.receiveStudentRecord.send({
      student,
      submissions: studentSubmissions
    });

  } catch (error) {
    console.error("Error fetching student record:", error);
  }
}

function setupAdminSubmissionListeners(elmApp) {
  fetchAdminSubmissions(elmApp);

  const submissionsRef = ref(database, 'submissions');
  onValue(submissionsRef, (snapshot) => {
    if (snapshot.exists()) {
      const data = snapshot.val();
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

function fetchAdminSubmissions(elmApp) {
  const submissionsRef = ref(database, 'submissions');

  get(submissionsRef)
    .then((snapshot) => {
      if (snapshot.exists()) {
        const data = snapshot.val();
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
    })
    .catch((error) => {
      console.error("Error fetching submissions:", error);
      elmApp.ports.receiveSubmissions.send([]);
    });
}

function saveAdminGrade(data, elmApp) {
  const submissionId = data.submissionId;
  const grade = data.grade;

  grade.gradedBy = auth.currentUser.email;
  grade.gradingDate = new Date().toISOString().split('T')[0];

  const submissionRef = ref(database, `submissions/${submissionId}`);

  update(submissionRef, { grade })
    .then(() => {
      elmApp.ports.gradeResult.send("Success: Grade saved successfully");
    })
    .catch((error) => {
      elmApp.ports.gradeResult.send("Error: " + error.message);
      console.error("Error saving grade:", error);
    });
}

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

function getPasswordResetErrorMessage(errorCode) {
  switch (errorCode) {
    case 'auth/invalid-email':
      return 'The email address is not valid.';
    case 'auth/user-not-found':
      return 'No account found with this email address.';
    default:
      return 'An error occurred. Please try again.';
  }
}

async function createNewStudentRecord(studentData, elmApp) {
  try {
    const { name } = studentData;

    if (!name || !isValidNameFormat(name)) {
      throw new Error("Student name must be in firstname.lastname format");
    }

    const studentId = sanitizeFirebasePath(name);
    const currentDate = new Date().toISOString().split('T')[0];

    const studentRecord = {
      name: name,
      created: currentDate,
      lastActive: currentDate
    };

    const studentRef = ref(database, `students/${studentId}`);
    const snapshot = await get(studentRef);

    if (snapshot.exists()) {
      const timestamp = Date.now();
      const uniqueId = `${studentId}_${timestamp}`;
      const uniqueRef = ref(database, `students/${uniqueId}`);

      await set(uniqueRef, studentRecord);

      elmApp.ports.studentCreated.send({
        id: uniqueId,
        ...studentRecord
      });
    } else {
      await set(studentRef, studentRecord);

      elmApp.ports.studentCreated.send({
        id: studentId,
        ...studentRecord
      });
    }
  } catch (error) {
    console.error("Error creating student record:", error);
    elmApp.ports.studentCreated.send({
      error: error.message || "Error creating student record"
    });
  }
}
