import { AuthService } from '../services/auth-service.js';
import { StudentService } from '../services/student-service.js';
import { SubmissionService } from '../services/submission-service.js';
import { BeltService } from '../services/belt-service.js';
import { AdminUserService } from '../services/admin-user-service.js';

const authService = new AuthService();
const studentService = new StudentService();
const submissionService = new SubmissionService();
const beltService = new BeltService();
const adminUserService = new AdminUserService();

export function initializeFirebase(elmApp) {
  // Authentication
  authService.onAuthStateChange((authState) => {
    elmApp.ports.receiveAuthState.send(authState);

    if (authState.isSignedIn) {
      // Load initial data
      loadSubmissions();
      loadBelts();
    }
  });

  elmApp.ports.signIn.subscribe(async function(credentials) {
    const result = await authService.signIn(credentials.email, credentials.password);
    elmApp.ports.receiveAuthResult.send(result);
  });

  elmApp.ports.signOut.subscribe(async function() {
    await authService.signOut();
  });

  // Password reset
  elmApp.ports.requestPasswordReset.subscribe(async function(email) {
    const result = await authService.sendPasswordReset(email);
    elmApp.ports.passwordResetResult.send(result);
  });

  // Submissions
  elmApp.ports.requestSubmissions.subscribe(loadSubmissions);

  elmApp.ports.saveGrade.subscribe(async function(data) {
    if (!authService.isAuthenticated()) {
      elmApp.ports.gradeResult.send("Error: Not authenticated");
      return;
    }

    try {
      await submissionService.updateGrade(data.submissionId, data.grade);
      elmApp.ports.gradeResult.send("Success: Grade saved successfully");
    } catch (error) {
      elmApp.ports.gradeResult.send("Error: " + error.message);
    }
  });

  // Students
  elmApp.ports.requestAllStudents.subscribe(async function() {
    if (!authService.isAuthenticated()) return;

    try {
      const students = await studentService.getAll();
      elmApp.ports.receiveAllStudents.send(students);
    } catch (error) {
      console.error("Error fetching students:", error);
      elmApp.ports.receiveAllStudents.send([]);
    }
  });

  // Helper functions
  async function loadSubmissions() {
    if (!authService.isAuthenticated()) return;

    try {
      const submissions = await submissionService.getAll();
      elmApp.ports.receiveSubmissions.send(submissions);
    } catch (error) {
      console.error("Error loading submissions:", error);
      elmApp.ports.receiveSubmissions.send([]);
    }
  }

  async function loadBelts() {
    try {
      const belts = await beltService.getAll();
      elmApp.ports.receiveBelts.send(belts);
    } catch (error) {
      console.error("Error loading belts:", error);
      elmApp.ports.receiveBelts.send([]);
    }
  }
}
