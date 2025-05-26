import { database, auth } from '../config/firebase-config.js';
import { ref, get, set, remove, update } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';
import {
  createUserWithEmailAndPassword,
  updateProfile,
  sendPasswordResetEmail
} from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js';
import { handleDatabaseError } from '../utils/error-handling.js';

export class AdminUserService {
  // Create new admin user
  async createAdminUser(userData) {
    try {
      const currentUser = auth.currentUser;
      if (!currentUser) {
        throw new Error('No authenticated user');
      }

      // Check if current user is superuser
      const currentUserData = await this.getAdminUser(currentUser.uid);
      if (!currentUserData || currentUserData.role !== 'superuser') {
        throw new Error('Only superusers can create admin accounts');
      }

      // Create user with Firebase Auth
      const userCredential = await createUserWithEmailAndPassword(
        auth,
        userData.email,
        userData.password
      );

      const newUser = userCredential.user;

      // Update display name if provided
      if (userData.displayName) {
        await updateProfile(newUser, {
          displayName: userData.displayName
        });
      }

      // Store admin user data in database
      const adminUserRef = ref(database, `admins/${newUser.uid}`);
      const adminData = {
        email: userData.email,
        displayName: userData.displayName || userData.email.split('@')[0],
        role: userData.role || 'admin',
        createdBy: currentUser.email,
        createdAt: new Date().toISOString()
      };

      await set(adminUserRef, adminData);

      return {
        success: true,
        message: `Admin user ${userData.email} created successfully`
      };
    } catch (error) {
      return {
        success: false,
        message: handleDatabaseError(error, 'create admin user')
      };
    }
  }

  // Get all admin users
  async getAllAdminUsers() {
    try {
      const adminsRef = ref(database, 'admins');
      const snapshot = await get(adminsRef);

      if (!snapshot.exists()) return [];

      const admins = snapshot.val();
      return Object.entries(admins).map(([uid, admin]) => ({
        uid,
        ...admin
      }));
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'get admin users'));
    }
  }

  // Get admin user by UID
  async getAdminUser(uid) {
    try {
      const adminRef = ref(database, `admins/${uid}`);
      const snapshot = await get(adminRef);

      if (!snapshot.exists()) return null;

      return { uid, ...snapshot.val() };
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'get admin user'));
    }
  }

  // Update admin user
  async updateAdminUser(userData) {
    try {
      const currentUser = auth.currentUser;
      if (!currentUser) {
        throw new Error('No authenticated user');
      }

      // Check permissions
      const currentUserData = await this.getAdminUser(currentUser.uid);
      if (!currentUserData || currentUserData.role !== 'superuser') {
        throw new Error('Only superusers can update admin accounts');
      }

      // Update database record
      const adminRef = ref(database, `admins/${userData.uid}`);
      const updates = {
        email: userData.email,
        displayName: userData.displayName,
        role: userData.role
      };

      await update(adminRef, updates);

      // Note: Updating email in Firebase Auth requires the user to be signed in
      // This is a limitation - in a real app, you'd need to handle this differently

      return {
        success: true,
        message: 'Admin user updated successfully'
      };
    } catch (error) {
      return {
        success: false,
        message: handleDatabaseError(error, 'update admin user')
      };
    }
  }

  // Delete admin user
  async deleteAdminUser(uid) {
    try {
      const currentUser = auth.currentUser;
      if (!currentUser) {
        throw new Error('No authenticated user');
      }

      // Check permissions
      const currentUserData = await this.getAdminUser(currentUser.uid);
      if (!currentUserData || currentUserData.role !== 'superuser') {
        throw new Error('Only superusers can delete admin accounts');
      }

      // Prevent self-deletion
      if (uid === currentUser.uid) {
        throw new Error('Cannot delete your own admin account');
      }

      // Check if admin user exists
      const adminRef = ref(database, `admins/${uid}`);
      const adminSnapshot = await get(adminRef);

      if (!adminSnapshot.exists()) {
        throw new Error('Admin user not found');
      }

      // Remove from database
      await remove(adminRef);

      // Note: Deleting user from Firebase Auth requires admin SDK
      // In a real app, you'd need a cloud function for this

      return {
        success: true,
        message: 'Admin user deleted successfully'
      };
    } catch (error) {
      return {
        success: false,
        message: handleDatabaseError(error, 'delete admin user')
      };
    }
  }

  // Send password reset email
  async sendPasswordReset(email) {
    try {
      await sendPasswordResetEmail(auth, email);
      return {
        success: true,
        message: 'Password reset email sent successfully'
      };
    } catch (error) {
      return {
        success: false,
        message: handleDatabaseError(error, 'send password reset')
      };
    }
  }

  // Check if user is admin
  async isAdmin(uid) {
    try {
      const adminData = await this.getAdminUser(uid);
      return !!adminData;
    } catch (error) {
      console.error('Error checking admin status:', error);
      return false;
    }
  }

  // Check if user is superuser
  async isSuperuser(uid) {
    try {
      const adminData = await this.getAdminUser(uid);
      return adminData && adminData.role === 'superuser';
    } catch (error) {
      console.error('Error checking superuser status:', error);
      return false;
    }
  }

  // Get user role
  async getUserRole(uid) {
    try {
      const adminData = await this.getAdminUser(uid);
      return adminData ? adminData.role : null;
    } catch (error) {
      console.error('Error getting user role:', error);
      return null;
    }
  }

  // Validate admin user data
  validateAdminUser(userData) {
    const errors = [];

    if (!userData.email || !userData.email.includes('@')) {
      errors.push('Valid email address is required');
    }

    if (!userData.password || userData.password.length < 6) {
      errors.push('Password must be at least 6 characters');
    }

    if (!userData.role || !['admin', 'superuser'].includes(userData.role)) {
      errors.push('Valid role (admin or superuser) is required');
    }

    return errors;
  }
}
