import { database } from '../config/firebase-config.js';
import { ref, get, set, update, remove } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';
import { handleDatabaseError } from '../utils/error-handling.js';

export class SubmissionService {
  async create(submissionData) {
    try {
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
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'create submission'));
    }
  }

  async getAll() {
    try {
      const submissionsRef = ref(database, 'submissions');
      const snapshot = await get(submissionsRef);

      if (!snapshot.exists()) return [];

      const data = snapshot.val();
      return Object.entries(data).map(([id, submission]) => ({
        id,
        ...submission
      }));
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'fetch submissions'));
    }
  }

  async getByStudentId(studentId) {
    try {
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
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'fetch student submissions'));
    }
  }

  async updateGrade(submissionId, gradeData) {
    try {
      const currentDate = new Date().toISOString().split('T')[0];
      const grade = {
        ...gradeData,
        gradingDate: currentDate
      };

      const submissionRef = ref(database, `submissions/${submissionId}`);
      await update(submissionRef, { grade });

      return grade;
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'update grade'));
    }
  }

  async delete(submissionId) {
    try {
      const submissionRef = ref(database, `submissions/${submissionId}`);
      const snapshot = await get(submissionRef);

      if (!snapshot.exists()) {
        throw new Error("Submission not found");
      }

      await remove(submissionRef);
      return submissionId;
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'delete submission'));
    }
  }
}
