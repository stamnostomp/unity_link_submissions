import { auth, database } from '../config/firebase-config.js';
import { ref, get, update } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';
import {
  signInWithEmailAndPassword,
  onAuthStateChanged,
  signOut,
  sendPasswordResetEmail
} from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js';
import { getAuthErrorMessage } from '../utils/error-handling.js';

export class AuthService {
  constructor() {
    this.currentUser = null;
  }

  async signIn(email, password) {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      return { success: true, user: userCredential.user };
    } catch (error) {
      return {
        success: false,
        message: getAuthErrorMessage(error.code)
      };
    }
  }

  async signOut() {
    try {
      await signOut(auth);
      this.currentUser = null;
      return { success: true };
    } catch (error) {
      return { success: false, message: error.message };
    }
  }

  async sendPasswordReset(email) {
    try {
      await sendPasswordResetEmail(auth, email);
      return {
        success: true,
        message: "Password reset email sent! Check your inbox."
      };
    } catch (error) {
      return {
        success: false,
        message: getAuthErrorMessage(error.code)
      };
    }
  }

  onAuthStateChange(callback) {
    return onAuthStateChanged(auth, async (user) => {
      if (user) {
        try {
          const adminRef = ref(database, `admins/${user.uid}`);
          const adminSnapshot = await get(adminRef);

          if (adminSnapshot.exists()) {
            const adminData = adminSnapshot.val();

            // Ensure role is set
            if (!adminData.role) {
              await update(adminRef, { role: "admin" });
              adminData.role = "admin";
            }

            this.currentUser = {
              uid: user.uid,
              email: user.email,
              displayName: user.displayName || user.email,
              role: adminData.role
            };

            callback({ user: this.currentUser, isSignedIn: true });
          } else {
            callback({ user: null, isSignedIn: false });
          }
        } catch (error) {
          console.error("Error fetching admin data:", error);
          callback({ user: null, isSignedIn: false });
        }
      } else {
        this.currentUser = null;
        callback({ user: null, isSignedIn: false });
      }
    });
  }

  getCurrentUser() {
    return this.currentUser;
  }

  isAuthenticated() {
    return this.currentUser !== null;
  }
}
