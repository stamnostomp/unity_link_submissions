// Firebase configuration for arcola-east-regina
// Branch: arcola-east-regina
// Generated: 2025-06-16T21:02:11Z

const firebaseConfig = {
  apiKey: "AIzaSyCSBvsGf_HAsc9LHc_hVEPj_fLzVpewocs",
  authDomain: "arcola-east-regina.firebaseapp.com",
  databaseURL: "https://arcola-east-regina-default-rtdb.firebaseio.com/",
  projectId: "arcola-east-regina",
  storageBucket: "arcola-east-regina.appspot.com",
  messagingSenderId: "241321870575",
  appId: "arcola-east-regina"
};

// Application configuration
const appConfig = {
  projectName: "arcola-east-regina",
  organizationName: "arcola-east-regina",
  environment: "arcola-east-regina",
  version: "2025.06.16",
  deploymentDate: "2025-06-16T21:02:11Z",
  brandColor: "",
  adminEmail: "stamno@pm.me"
};

// Export for both environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { firebaseConfig, appConfig };
} else {
  window.firebaseConfig = firebaseConfig;
  window.appConfig = appConfig;
}
