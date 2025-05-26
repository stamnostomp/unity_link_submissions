export function getAuthErrorMessage(errorCode) {
  const errorMessages = {
    'auth/invalid-email': 'The email address is not valid.',
    'auth/user-disabled': 'This account has been disabled.',
    'auth/user-not-found': 'No account found with this email.',
    'auth/wrong-password': 'Incorrect password.',
    'auth/too-many-requests': 'Too many failed login attempts. Please try again later.',
    'auth/network-request-failed': 'Network error. Please check your connection.'
  };

  return errorMessages[errorCode] || 'An authentication error occurred. Please try again.';
}

export function handleDatabaseError(error, operation) {
  console.error(`Error during ${operation}:`, error);
  return error.message || `Failed to ${operation}`;
}
