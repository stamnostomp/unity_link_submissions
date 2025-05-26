import { database } from '../config/firebase-config.js';
import { ref, get, set, update } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';
import { sanitizeFirebasePath } from '../utils/sanitization.js';
import { handleDatabaseError } from '../utils/error-handling.js';

export function initializeFirebase(elmApp) {
  // Student search
  elmApp.ports.findStudent.subscribe(async function(studentName) {
    try {
      const student = await findStudentByName(studentName);

      if (student) {
        const submissions = await getSubmissionsByStudentId(student.id);
        const studentWithSubmissions = { ...student, submissions };
        elmApp.ports.studentFound.send(studentWithSubmissions);
      } else {
        elmApp.ports.studentFound.send(null);
      }
    } catch (error) {
      console.error("Error finding student:", error);
      elmApp.ports.studentFound.send(null);
    }
  });

  // Submission creation
  elmApp.ports.saveSubmission.subscribe(async function(submissionData) {
    try {
      await createSubmission(submissionData);
      elmApp.ports.submissionResult.send("Success: Submission saved successfully");
    } catch (error) {
      console.error("Error saving submission:", error);
      elmApp.ports.submissionResult.send("Error: " + error.message);
    }
  });

  // Belt requests
  elmApp.ports.requestBelts.subscribe(async function() {
    try {
      const belts = await getAllBelts();
      elmApp.ports.receiveBelts.send(belts);
    } catch (error) {
      console.error("Error fetching belts:", error);
      elmApp.ports.receiveBelts.send([]);
    }
  });
}

// Helper functions
async function findStudentByName(studentName) {
  const sanitizedName = sanitizeFirebasePath(studentName);

  // Try direct lookup first
  const directRef = ref(database, `students/${sanitizedName}`);
  const directSnapshot = await get(directRef);

  if (directSnapshot.exists()) {
    return {
      ...directSnapshot.val(),
      id: sanitizedName
    };
  }

  // Fallback to searching by name field
  const studentsRef = ref(database, 'students');
  const snapshot = await get(studentsRef);

  if (!snapshot.exists()) return null;

  const studentsData = snapshot.val();
  for (const studentId in studentsData) {
    const student = studentsData[studentId];
    if (student.name === studentName) {
      return { ...student, id: studentId };
    }
  }

  return null;
}

async function getSubmissionsByStudentId(studentId) {
  const submissionsRef = ref(database, 'submissions');
  const snapshot = await get(submissionsRef);

  if (!snapshot.exists()) return [];

  const submissionsData = snapshot.val();
  const studentSubmissions = [];

  for (const submissionId in submissionsData) {
    const submission = submissionsData[submissionId];
    if (submission.studentId === studentId) {
      studentSubmissions.push({
        id: submissionId,
        ...submission
      });
    }
  }

  // Sort by date (newest first)
  return studentSubmissions.sort((a, b) =>
    new Date(b.submissionDate) - new Date(a.submissionDate)
  );
}

async function createSubmission(submissionData) {
  const submissionId = submissionData.id;
  const currentDate = new Date().toISOString().split('T')[0];

  const submissionToSave = {
    ...submissionData,
    submissionDate: currentDate
  };

  await set(ref(database, `submissions/${submissionId}`), submissionToSave);

  // Update student's lastActive date
  const studentRef = ref(database, `students/${submissionData.studentId}`);
  await update(studentRef, { lastActive: currentDate });

  return submissionToSave;
}

async function getAllBelts() {
  const beltsRef = ref(database, 'belts');
  const snapshot = await get(beltsRef);

  if (snapshot.exists()) {
    const beltsData = snapshot.val();
    const belts = [];

    for (const beltId in beltsData) {
      const belt = beltsData[beltId];
      belts.push({
        id: beltId,
        ...belt
      });
    }

    // Sort belts by order
    return belts.sort((a, b) => a.order - b.order);
  } else {
    // Create default belts if none exist
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

    // Save default belts
    for (const belt of defaultBelts) {
      await set(ref(database, `belts/${belt.id}`), belt);
    }

    return defaultBelts;
  }
}
