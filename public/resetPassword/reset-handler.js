// handle-reset.js
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import { getAuth, verifyPasswordResetCode, confirmPasswordReset } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";

// Your Firebase configuration
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
const auth = getAuth(app);

document.addEventListener('DOMContentLoaded', function() {
  // Get action code from URL
  const urlParams = new URLSearchParams(window.location.search);
  const mode = urlParams.get('mode');
  const actionCode = urlParams.get('oobCode');

  // Get DOM elements
  const emailElement = document.getElementById('email');
  const newPasswordInput = document.getElementById('newPassword');
  const confirmPasswordInput = document.getElementById('confirmPassword');
  const resetForm = document.getElementById('resetForm');
  const matchError = document.getElementById('match-error');
  const errorMessage = document.getElementById('error-message');
  const resetContainer = document.getElementById('reset-container');

  // Check if this is a valid password reset
  if (mode === 'resetPassword' && actionCode) {
    // Verify the action code is valid
    verifyPasswordResetCode(auth, actionCode)
      .then((email) => {
        // Display the email address
        if (emailElement) {
          emailElement.textContent = email;
        }

        // Set up form submission handler
        if (resetForm) {
          resetForm.addEventListener('submit', (e) => {
            e.preventDefault();

            if (!newPasswordInput || !confirmPasswordInput) {
              console.error("Password inputs not found");
              return;
            }

            const newPassword = newPasswordInput.value;
            const confirmPassword = confirmPasswordInput.value;

            // Clear previous errors
            if (matchError) {
              matchError.textContent = '';
            }

            // Validate passwords match and meet minimum requirements
            if (newPassword !== confirmPassword) {
              if (matchError) {
                matchError.textContent = 'Passwords do not match';
              }
              return;
            }

            if (newPassword.length < 6) {
              if (matchError) {
                matchError.textContent = 'Password must be at least 6 characters';
              }
              return;
            }

            // Complete the password reset
            confirmPasswordReset(auth, actionCode, newPassword)
              .then(() => {
                // Password reset successful
                if (resetContainer) {
                  resetContainer.innerHTML = `
                    <div class="success-container">
                      <h2>Password Reset Successful</h2>
                      <p>Your password has been updated. You can now sign in with your new password.</p>
                      <a href="/admin" class="login-link">Go to Login</a>
                    </div>
                  `;
                }
              })
              .catch((error) => {
                // Handle error
                console.error("Error confirming password reset:", error);
                if (errorMessage) {
                  errorMessage.textContent = error.message || 'An error occurred. Please try again.';
                }
              });
          });
        }
      })
      .catch((error) => {
        // Invalid or expired action code
        console.error("Error verifying password reset code:", error);
        if (resetContainer) {
          resetContainer.innerHTML = `
            <div class="error-container">
              <h2>Invalid or Expired Link</h2>
              <p>Your password reset link has expired or is invalid.
                 Please request a new password reset link.</p>
              <a href="/admin" class="login-link">Return to Login</a>
            </div>
          `;
        }
      });
  } else {
    // Invalid mode parameter
    console.error("Invalid mode or missing action code");
    if (resetContainer) {
      resetContainer.innerHTML = `
        <div class="error-container">
          <h2>Invalid Request</h2>
          <p>This password reset link is invalid. Please request a new password reset link.</p>
          <a href="/admin" class="login-link">Return to Login</a>
        </div>
      `;
    }
  }
});
