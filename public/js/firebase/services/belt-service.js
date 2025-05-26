import { database } from '../config/firebase-config.js';
import { ref, get, set, remove, query, orderByChild } from 'https://www.gstatic.com/firebasejs/10.8.0/firebase-database.js';
import { handleDatabaseError } from '../utils/error-handling.js';

export class BeltService {
  // Get all belts
  async getBelts() {
    try {
      const beltsRef = ref(database, 'belts');
      const snapshot = await get(beltsRef);

      if (!snapshot.exists()) return [];

      const belts = snapshot.val();
      return Object.entries(belts)
        .map(([id, belt]) => ({ id, ...belt }))
        .sort((a, b) => a.order - b.order);
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'get belts'));
    }
  }

  async getAll() {
    return await this.getBelts();
  }

  // Save belt (create or update)
  async saveBelt(beltData) {
    try {
      // Check if belt with same order already exists (for different belt)
      const beltsRef = ref(database, 'belts');
      const snapshot = await get(beltsRef);

      if (snapshot.exists()) {
        const belts = snapshot.val();
        const existingBelt = Object.entries(belts).find(([id, belt]) =>
          belt.order === beltData.order && id !== beltData.id
        );

        if (existingBelt) {
          throw new Error(`A belt with order ${beltData.order} already exists`);
        }
      }

      const beltRef = ref(database, `belts/${beltData.id}`);
      await set(beltRef, {
        name: beltData.name,
        color: beltData.color,
        order: beltData.order,
        gameOptions: beltData.gameOptions
      });

      return 'Belt saved successfully';
    } catch (error) {
      return `Error: ${handleDatabaseError(error, 'save belt')}`;
    }
  }

  // Delete belt
  async deleteBelt(beltId) {
    try {
      // Check if belt exists
      const beltRef = ref(database, `belts/${beltId}`);
      const beltSnapshot = await get(beltRef);

      if (!beltSnapshot.exists()) {
        throw new Error('Belt not found');
      }

      // Check if belt is being used by any submissions
      const submissionsRef = ref(database, 'submissions');
      const submissionsSnapshot = await get(submissionsRef);

      if (submissionsSnapshot.exists()) {
        const submissions = submissionsSnapshot.val();
        const beltInUse = Object.values(submissions).some(submission =>
          submission.beltLevel === beltId
        );

        if (beltInUse) {
          throw new Error('Cannot delete belt: it is being used by existing submissions');
        }
      }

      await remove(beltRef);
      return 'Belt deleted successfully';
    } catch (error) {
      return `Error: ${handleDatabaseError(error, 'delete belt')}`;
    }
  }

  // Get belt by ID
  async getBelt(beltId) {
    try {
      const beltRef = ref(database, `belts/${beltId}`);
      const snapshot = await get(beltRef);

      if (!snapshot.exists()) return null;

      return { id: beltId, ...snapshot.val() };
    } catch (error) {
      throw new Error(handleDatabaseError(error, 'get belt'));
    }
  }

  // Get game options for a belt
  async getGameOptions(beltId) {
    try {
      const belt = await this.getBelt(beltId);
      return belt ? belt.gameOptions : [];
    } catch (error) {
      console.error('Error getting game options:', error);
      return [];
    }
  }

  // Validate belt data
  validateBelt(beltData) {
    const errors = [];

    if (!beltData.name || beltData.name.trim() === '') {
      errors.push('Belt name is required');
    }

    if (!beltData.color || !beltData.color.match(/^#[0-9A-Fa-f]{6}$/)) {
      errors.push('Valid belt color (hex format) is required');
    }

    if (typeof beltData.order !== 'number' || beltData.order < 1) {
      errors.push('Belt order must be a positive number');
    }

    if (!Array.isArray(beltData.gameOptions) || beltData.gameOptions.length === 0) {
      errors.push('At least one game option is required');
    }

    return errors;
  }
}
