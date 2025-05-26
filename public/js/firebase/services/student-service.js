import { database } from '../config/firebase-config.js';
import { ref, get, set, update, remove, push, query, orderByChild } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';
import { handleDatabaseError } from '../utils/error-handling.js';

export class StudentService {
  
  // Find student by name
  async findStudent(studentName) {
    try {
      const studentsRef = ref(database, 'students');
      const snapshot = await get(studentsRef);

      if (!snapshot.exists()) return null;

      const students = snapshot.val();
      const foundStudent = Object.entries(students).find(([id, student]) =>
        student.name === studentName
      );

      if (!foundStudent) return null;

      const [studentId, studentData] = foundStudent;

      // Get student submissions
      const submissionsRef = ref(database, 'submissions');
      const submissionsSnapshot = await get(submissionsRef);

      let submissions = [];
      if (submissionsSnapshot.exists()) {
        const allSubmissions = submissionsSnapshot.val();
        submissions = Object.entries(allSubmissions)
          .filter(([id, submission]) => submission.studentId === studentId)
          .map(([id, submission]) => ({ id, ...submission }))
          .sort((a, b) => new Date(b.submissionDate) - new Date(a.submissionDate));
      }

      return {
        id: studentId,
        ...studentData,
        submissions
      };
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'find student'));
    }
  }

  // Get student record with submissions
  async getStudentRecord(studentId) {
    try {
      const studentRef = ref(database, `students/${studentId}`);
      const studentSnapshot = await get(studentRef);

      if (!studentSnapshot.exists()) {
        throw new Error('Student not found');
      }

      const student = { id: studentId, ...studentSnapshot.val() };

      // Get student submissions
      const submissionsRef = ref(database, 'submissions');
      const submissionsSnapshot = await get(submissionsRef);

      let submissions = [];
      if (submissionsSnapshot.exists()) {
        const allSubmissions = submissionsSnapshot.val();
        submissions = Object.entries(allSubmissions)
          .filter(([id, submission]) => submission.studentId === studentId)
          .map(([id, submission]) => ({ id, ...submission }))
          .sort((a, b) => new Date(b.submissionDate) - new Date(a.submissionDate));
      }

      return { student, submissions };
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'get student record'));
    }
  }

  // Create new student
  async createStudent(studentData) {
    try {
      const studentsRef = ref(database, 'students');
      const newStudentRef = push(studentsRef);
      const studentId = newStudentRef.key;

      const currentDate = new Date().toISOString().split('T')[0];
      const student = {
        name: studentData.name,
        created: currentDate,
        lastActive: currentDate
      };

      await set(newStudentRef, student);

      return {
        id: studentId,
        ...student
      };
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'create student'));
    }
  }

  // Get all students
  async getAllStudents() {
    try {
      const studentsRef = ref(database, 'students');
      const snapshot = await get(studentsRef);

      if (!snapshot.exists()) return [];

      const students = snapshot.val();
      return Object.entries(students).map(([id, student]) => ({
        id,
        ...student
      }));
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'get all students'));
    }
  }

  // Update student
  async updateStudent(studentData) {
    try {
      const studentRef = ref(database, `students/${studentData.id}`);
      const currentDate = new Date().toISOString().split('T')[0];
      const updates = {
        name: studentData.name,
        lastActive: currentDate
      };

      await update(studentRef, updates);

      const updatedSnapshot = await get(studentRef);
      return {
        id: studentData.id,
        ...updatedSnapshot.val()
      };
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'update student'));
    }
  }

  // Delete student
  async deleteStudent(studentId) {
    try {
      // Check if student exists
      const studentRef = ref(database, `students/${studentId}`);
      const studentSnapshot = await get(studentRef);

      if (!studentSnapshot.exists()) {
        throw new Error('Student not found');
      }

      // Delete student record
      await remove(studentRef);

      // Delete all student submissions
      const submissionsRef = ref(database, 'submissions');
      const submissionsSnapshot = await get(submissionsRef);

      if (submissionsSnapshot.exists()) {
        const submissions = submissionsSnapshot.val();
        const deletePromises = Object.entries(submissions)
          .filter(([id, submission]) => submission.studentId === studentId)
          .map(([id]) => remove(ref(database, `submissions/${id}`)));

        await Promise.all(deletePromises);
      }

      return studentId;
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'delete student'));
    }
  }

  // Save submission
  async saveSubmission(submissionData) {
    try {
      const submissionsRef = ref(database, 'submissions');
      const newSubmissionRef = push(submissionsRef);

      const currentDate = new Date().toISOString().split('T')[0];
      const submissionToSave = {
        ...submissionData,
        submissionDate: currentDate
      };

      await set(newSubmissionRef, submissionToSave);

      // Update student's last active time
      const studentRef = ref(database, `students/${submissionData.studentId}`);
      await update(studentRef, {
        lastActive: currentDate
      });

      return 'Submission saved successfully';
    } catch (error) {
      return `Error: ${handleDatabaseError(error, 'save submission')}`;
    }
  }
}
