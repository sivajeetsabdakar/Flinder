const supabase = require('../supabaseClient');

/**
 * Get preferences by user ID
 * @param {string} userId - User ID
 * @returns {Object} The preferences object or error
 */
const getPreferencesByUserId = async (userId) => {
  try {
    const { data: preferences, error } = await supabase
      .from('preferences')
      .select('*')
      .eq('user_id', userId)
      .single();
    
    if (error) throw error;
    
    // Format preferences for API response
    const formattedPreferences = {
      userId: preferences.user_id,
      critical: preferences.critical,
      nonCritical: preferences.non_critical,
      discoverySettings: preferences.discovery_settings,
      interests: preferences.interests
    };
    
    return { preferences: formattedPreferences, error: null };
  } catch (error) {
    console.error('Get preferences error:', error);
    return { preferences: null, error };
  }
};

/**
 * Create or update user preferences
 * @param {string} userId - User ID
 * @param {Object} preferencesData - Preferences data
 * @returns {Object} The updated preferences or error
 */
const createOrUpdatePreferences = async (userId, preferencesData) => {
  try {
    // Check if preferences exist
    const { data: existingPreferences } = await supabase
      .from('preferences')
      .select('user_id')
      .eq('user_id', userId)
      .single();
    
    // Format preferences data for database
    const dbPreferencesData = {
      user_id: userId,
      critical: preferencesData.critical,
      non_critical: preferencesData.nonCritical || {},
      discovery_settings: preferencesData.discoverySettings || {
        ageRange: { min: 18, max: 99 },
        distance: 50,
        showMeToOthers: true
      },
      interests: preferencesData.interests || {}
    };
    
    let result;
    
    // Insert or update preferences
    if (!existingPreferences) {
      // Create new preferences
      result = await supabase
        .from('preferences')
        .insert(dbPreferencesData)
        .select();
    } else {
      // Update existing preferences
      result = await supabase
        .from('preferences')
        .update(dbPreferencesData)
        .eq('user_id', userId)
        .select();
    }
    
    if (result.error) throw result.error;
    
    // Format preferences for API response
    const formattedPreferences = {
      userId,
      critical: dbPreferencesData.critical,
      nonCritical: dbPreferencesData.non_critical,
      discoverySettings: dbPreferencesData.discovery_settings,
      interests: dbPreferencesData.interests
    };
    
    return { preferences: formattedPreferences, error: null };
  } catch (error) {
    console.error('Update preferences error:', error);
    return { preferences: null, error };
  }
};

module.exports = {
  getPreferencesByUserId,
  createOrUpdatePreferences
}; 