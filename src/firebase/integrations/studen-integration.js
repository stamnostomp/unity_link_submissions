import { StudentService } from '../services/student-service.js';
import { SubmissionService } from '../services/submission-service.js';
import { BeltService } from '../services/belt-service.js';

const studentService = new StudentService();
const submissionService = new SubmissionService();
const beltService = new BeltService();

export function initializeFirebase(elmApp) {
  // Student search
  elmApp.ports.findStudent.subscribe(async function(studentName) {
    try {
      const student = await studentService.findByName(studentName);

      if (student) {
        const submissions = await submissionService.getByStudentId(student.id);
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
      await submissionService.create(submissionData);
      elmApp.ports.submissionResult.send("Success: Submission saved successfully");
    } catch (error) {
      console.error("Error saving submission:", error);
      elmApp.ports.submissionResult.send("Error: " + error.message);
    }
  });

  // Belt requests
  elmApp.ports.requestBelts.subscribe(async function() {
    try {
      const belts = await beltService.getAll();
      elmApp.ports.receiveBelts.send(belts);
    } catch (error) {
      console.error("Error fetching belts:", error);
      elmApp.ports.receiveBelts.send([]);
    }
  });
