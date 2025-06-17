// student-firebase.js - Integrated with Points System (FIXED VERSION)
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
 * Helper function to get current date
 * @return {string} Current date in YYYY-MM-DD format
 */
function getCurrentDate() {
    return new Date().toISOString().split('T')[0];
}

/**
 * Helper function to generate unique IDs
 * @param {string} prefix - Prefix for the ID
 * @return {string} Generated unique ID
 */
function generateId(prefix) {
    return prefix + '-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
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

  // EXISTING FUNCTIONALITY
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

  // POINTS SYSTEM FUNCTIONALITY
  // Listen for student points requests
  elmApp.ports.requestStudentPoints.subscribe(function(studentId) {
    requestStudentPointsWithAuth(studentId, elmApp);
  });

  // Listen for point rewards requests
  elmApp.ports.requestPointRewards.subscribe(function() {
    requestPointRewardsWithAuth(elmApp);
  });

  // Listen for point transactions requests
  elmApp.ports.requestPointTransactions.subscribe(function(studentId) {
    requestPointTransactionsWithAuth(studentId, elmApp);
  });

  // Listen for reward redemption requests
  elmApp.ports.redeemPointReward.subscribe(function(redemptionData) {
    redeemPointRewardWithAuth(redemptionData, elmApp);
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
      submissionDate: getCurrentDate(),
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

      // POINTS SYSTEM: Auto-load student points when student is found
      await loadStudentPoints(foundStudent.id, elmApp);

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

        // POINTS SYSTEM: Auto-load student points when student is found
        await loadStudentPoints(foundStudent.id, elmApp);

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
    const currentDate = getCurrentDate();

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

// =============================================================================
// POINTS SYSTEM FUNCTIONALITY
// =============================================================================

/**
 * Load student points automatically (called when student is found)
 * @param {string} studentId - The student ID
 * @param {Object} elmApp - The Elm application instance
 */
async function loadStudentPoints(studentId, elmApp) {
  try {
    const pointsRef = ref(database, `studentPoints/${studentId}`);
    const snapshot = await get(pointsRef);

    if (snapshot.exists()) {
      const studentPoints = snapshot.val();
      elmApp.ports.receiveStudentPoints.send(studentPoints);
    } else {
      // Create initial points record if it doesn't exist
      const initialPoints = {
        studentId: studentId,
        currentPoints: 0,
        totalEarned: 0,
        totalRedeemed: 0,
        lastUpdated: getCurrentDate()
      };

      await set(pointsRef, initialPoints);
      elmApp.ports.receiveStudentPoints.send(initialPoints);
    }
  } catch (error) {
    console.warn('Could not load student points:', error);
    // Send default points if there's an error
    elmApp.ports.receiveStudentPoints.send({
      studentId: studentId,
      currentPoints: 0,
      totalEarned: 0,
      totalRedeemed: 0,
      lastUpdated: getCurrentDate()
    });
  }
}

/**
 * Request student points with authentication
 * @param {string} studentId - The student ID
 * @param {Object} elmApp - The Elm application instance
 */
async function requestStudentPointsWithAuth(studentId, elmApp) {
  try {
    await initializeStudentAuth();
    await requestStudentPoints(studentId, elmApp);
  } catch (error) {
    console.error("Authentication failed for student points:", error);
    elmApp.ports.receiveStudentPoints.send({
      studentId: studentId,
      currentPoints: 0,
      totalEarned: 0,
      totalRedeemed: 0,
      lastUpdated: getCurrentDate()
    });
  }
}

/**
 * Request student points
 * @param {string} studentId - The student ID
 * @param {Object} elmApp - The Elm application instance
 */
async function requestStudentPoints(studentId, elmApp) {
  try {
    const pointsRef = ref(database, `studentPoints/${studentId}`);
    const snapshot = await get(pointsRef);

    if (snapshot.exists()) {
      const studentPoints = snapshot.val();
      elmApp.ports.receiveStudentPoints.send(studentPoints);
    } else {
      // Create initial points record if it doesn't exist
      const initialPoints = {
        studentId: studentId,
        currentPoints: 0,
        totalEarned: 0,
        totalRedeemed: 0,
        lastUpdated: getCurrentDate()
      };

      await set(pointsRef, initialPoints);
      elmApp.ports.receiveStudentPoints.send(initialPoints);
    }
  } catch (error) {
    console.error('Error loading student points:', error);
    elmApp.ports.receiveStudentPoints.send({
      studentId: studentId,
      currentPoints: 0,
      totalEarned: 0,
      totalRedeemed: 0,
      lastUpdated: getCurrentDate()
    });
  }
}

/**
 * Request point rewards with authentication
 * @param {Object} elmApp - The Elm application instance
 */
async function requestPointRewardsWithAuth(elmApp) {
  try {
    await initializeStudentAuth();
    await requestPointRewards(elmApp);
  } catch (error) {
    console.error("Authentication failed for point rewards:", error);
    elmApp.ports.receivePointRewards.send([]);
  }
}

/**
 * Request point rewards
 * @param {Object} elmApp - The Elm application instance
 */
async function requestPointRewards(elmApp) {
  try {
    const rewardsRef = ref(database, 'pointRewards');
    const snapshot = await get(rewardsRef);

    if (snapshot.exists()) {
      const rewardsData = snapshot.val();
      const rewards = Object.keys(rewardsData)
        .map(id => ({
          id,
          ...rewardsData[id]
        }))
        .filter(reward => reward.isActive) // Only show active rewards
        .sort((a, b) => a.order - b.order); // Sort by order

      elmApp.ports.receivePointRewards.send(rewards);
    } else {
      elmApp.ports.receivePointRewards.send([]);
    }
  } catch (error) {
    console.error('Error loading point rewards:', error);
    elmApp.ports.receivePointRewards.send([]);
  }
}

/**
 * Request point transactions with authentication
 * @param {string} studentId - The student ID
 * @param {Object} elmApp - The Elm application instance
 */
async function requestPointTransactionsWithAuth(studentId, elmApp) {
  try {
    await initializeStudentAuth();
    await requestPointTransactions(studentId, elmApp);
  } catch (error) {
    console.error("Authentication failed for point transactions:", error);
    elmApp.ports.receivePointTransactions.send([]);
  }
}

/**
 * Request point transactions for a student
 * @param {string} studentId - The student ID
 * @param {Object} elmApp - The Elm application instance
 */
async function requestPointTransactions(studentId, elmApp) {
  try {
    const transactionsRef = ref(database, 'pointTransactions');
    const snapshot = await get(transactionsRef);

    if (snapshot.exists()) {
      const transactionsData = snapshot.val();
      const transactions = Object.keys(transactionsData)
        .map(id => ({
          id,
          ...transactionsData[id]
        }))
        .filter(transaction => transaction.studentId === studentId)
        .sort((a, b) => new Date(b.date) - new Date(a.date)); // Sort by date, newest first

      elmApp.ports.receivePointTransactions.send(transactions);
    } else {
      elmApp.ports.receivePointTransactions.send([]);
    }
  } catch (error) {
    console.error('Error loading point transactions:', error);
    elmApp.ports.receivePointTransactions.send([]);
  }
}

/**
 * Redeem point reward with authentication
 * @param {Object} redemptionData - The redemption data
 * @param {Object} elmApp - The Elm application instance
 */
async function redeemPointRewardWithAuth(redemptionData, elmApp) {
  try {
    await initializeStudentAuth();
    await redeemPointReward(redemptionData, elmApp);
  } catch (error) {
    console.error("Authentication failed for reward redemption:", error);
    elmApp.ports.pointRedemptionResult.send("Error: Authentication failed");
  }
}

/**
 * Redeem point reward - FIXED VERSION TO HANDLE STOCK PROPERLY
 * @param {Object} redemptionData - The redemption data
 * @param {Object} elmApp - The Elm application instance
 */
async function redeemPointReward(redemptionData, elmApp) {
  try {
    const { rewardId, rewardName, rewardDescription, pointCost, studentId, studentName } = redemptionData;

    console.log('Processing redemption:', { rewardId, rewardName, pointCost, studentId });

    // Check current points
    const pointsRef = ref(database, `studentPoints/${studentId}`);
    const pointsSnapshot = await get(pointsRef);

    if (!pointsSnapshot.exists()) {
      elmApp.ports.pointRedemptionResult.send("Error: Student points record not found");
      return;
    }

    const currentPoints = pointsSnapshot.val();

    if (currentPoints.currentPoints < pointCost) {
      elmApp.ports.pointRedemptionResult.send("Error: Insufficient points for this redemption");
      return;
    }

    // Check stock availability
    const rewardRef = ref(database, `pointRewards/${rewardId}`);
    const rewardSnapshot = await get(rewardRef);

    if (!rewardSnapshot.exists()) {
      elmApp.ports.pointRedemptionResult.send("Error: Reward not found");
      return;
    }

    const reward = rewardSnapshot.val();
    console.log('Reward data:', reward);
    console.log('Stock value:', reward.stock, 'Type:', typeof reward.stock);

    if (!reward.isActive) {
      elmApp.ports.pointRedemptionResult.send("Error: This reward is no longer available");
      return;
    }

    // CRITICAL FIX: Proper stock validation
    // Check if reward has limited stock (not null and not undefined)
    const hasLimitedStock = reward.stock !== null && reward.stock !== undefined && typeof reward.stock === 'number';

    if (hasLimitedStock && reward.stock <= 0) {
      elmApp.ports.pointRedemptionResult.send("Error: This reward is out of stock");
      return;
    }

    // Prepare updates
    const updates = {};

    // Generate redemption ID
    const redemptionId = generateId('redemption');

    // Update student points
    const newCurrentPoints = currentPoints.currentPoints - pointCost;
    const newTotalRedeemed = currentPoints.totalRedeemed + pointCost;

    updates[`studentPoints/${studentId}`] = {
      ...currentPoints,
      currentPoints: newCurrentPoints,
      totalRedeemed: newTotalRedeemed,
      lastUpdated: getCurrentDate()
    };

    // Create redemption record
    updates[`pointRedemptions/${redemptionId}`] = {
      id: redemptionId,
      studentId: studentId,
      studentName: studentName,
      pointsRedeemed: pointCost,
      rewardName: rewardName,
      rewardDescription: rewardDescription,
      redeemedBy: studentName, // Student redeemed it themselves
      redemptionDate: getCurrentDate(),
      status: 'pending'
    };

    // Create transaction record
    const transactionId = generateId('transaction');
    updates[`pointTransactions/${transactionId}`] = {
      id: transactionId,
      studentId: studentId,
      studentName: studentName,
      transactionType: 'Redemption',
      points: pointCost,
      reason: `Redeemed: ${rewardName}`,
      category: 'redemption',
      adminEmail: 'student-self-redemption',
      date: getCurrentDate()
    };

    // CRITICAL FIX: Only update stock if it's limited stock
    if (hasLimitedStock) {
      const newStock = reward.stock - 1;
      console.log('Updating stock from', reward.stock, 'to', newStock);

      // Validate that the new stock value is not NaN
      if (isNaN(newStock)) {
        console.error('Stock calculation resulted in NaN:', { originalStock: reward.stock, newStock });
        elmApp.ports.pointRedemptionResult.send("Error: Invalid stock calculation");
        return;
      }

      updates[`pointRewards/${rewardId}/stock`] = newStock;
    } else {
      console.log('Reward has unlimited stock, not updating stock value');
    }

    console.log('Final updates to apply:', updates);

    // Apply all updates atomically
    await update(ref(database), updates);

    console.log('Redemption successful');
    elmApp.ports.pointRedemptionResult.send(`Successfully redeemed ${rewardName}! Your redemption is pending approval.`);

  } catch (error) {
    console.error('Error processing redemption:', error);
    console.error('Error details:', {
      name: error.name,
      message: error.message,
      stack: error.stack
    });
    elmApp.ports.pointRedemptionResult.send(`Error: Failed to process redemption - ${error.message}`);
  }
}

// =============================================================================
// REAL-TIME LISTENERS (Optional Enhancement)
// =============================================================================

let currentStudentId = null;
let pointsListener = null;
let rewardsListener = null;

/**
 * Set up real-time listeners for points system updates
 * @param {string} studentId - The student ID to listen for
 * @param {Object} elmApp - The Elm application instance
 */
export function setupPointsListeners(studentId, elmApp) {
  // Clean up existing listeners
  if (pointsListener) {
    pointsListener();
  }
  if (rewardsListener) {
    rewardsListener();
  }

  currentStudentId = studentId;

  // Listen for student points changes
  const pointsRef = ref(database, `studentPoints/${studentId}`);
  pointsListener = pointsRef.on('value', (snapshot) => {
    if (snapshot.exists()) {
      elmApp.ports.receiveStudentPoints.send(snapshot.val());
    }
  });

  // Listen for rewards changes
  const rewardsRef = ref(database, 'pointRewards');
  rewardsListener = rewardsRef.on('value', (snapshot) => {
    if (snapshot.exists()) {
      const rewardsData = snapshot.val();
      const rewards = Object.keys(rewardsData)
        .map(id => ({
          id,
          ...rewardsData[id]
        }))
        .filter(reward => reward.isActive)
        .sort((a, b) => a.order - b.order);

      elmApp.ports.receivePointRewards.send(rewards);
    }
  });
}

/**
 * Clean up real-time listeners
 */
export function cleanupPointsListeners() {
  if (pointsListener) {
    pointsListener();
    pointsListener = null;
  }
  if (rewardsListener) {
    rewardsListener();
    rewardsListener = null;
  }
  currentStudentId = null;
}

// Cleanup function for page unload
window.addEventListener('beforeunload', () => {
  cleanupPointsListeners();
});

console.log('Student Firebase integration with points system loaded successfully');
