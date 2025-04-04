const supabase = require('../supabaseClient');

/**
 * Get profile by user ID
 * @param {string} userId - User ID
 * @returns {Object} The profile object or error
 */
const getProfileByUserId = async (userId) => {
  try {
    // Get user profile
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', userId)
      .single();
    
    if (error) throw error;
    
    // Get profile pictures
    const { data: pictures, error: picturesError } = await supabase
      .from('profile_pictures')
      .select('id, url, is_primary, uploaded_at')
      .eq('user_id', userId);
    
    if (picturesError) throw picturesError;
    
    // Format the profile data according to API spec
    const formattedProfile = {
      userId: profile.user_id,
      bio: profile.bio,
      generatedDescription: profile.generated_description,
      interests: profile.interests || [],
      profilePictures: pictures.map(pic => ({
        id: pic.id,
        url: pic.url,
        isPrimary: pic.is_primary,
        uploadedAt: pic.uploaded_at
      })),
      location: profile.location,
      budget: profile.budget,
      roomPreference: profile.room_preference,
      genderPreference: profile.gender_preference,
      moveInDate: profile.move_in_date,
      leaseDuration: profile.lease_duration,
      lifestyle: profile.lifestyle,
      languages: profile.languages || []
    };
    
    return { profile: formattedProfile, error: null };
  } catch (error) {
    console.error('Get profile error:', error);
    return { profile: null, error };
  }
};

/**
 * Create or update a user profile
 * @param {string} userId - User ID
 * @param {Object} profileData - Profile data
 * @returns {Object} The updated profile or error
 */
const createOrUpdateProfile = async (userId, profileData) => {
  try {
    // Check if profile exists
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('user_id')
      .eq('user_id', userId)
      .single();
    
    // Format profile data for database
    const dbProfileData = {
      user_id: userId,
      bio: profileData.bio,
      generated_description: profileData.generatedDescription || profileData.bio,
      interests: profileData.interests || [],
      location: profileData.location,
      budget: profileData.budget,
      room_preference: profileData.roomPreference,
      gender_preference: profileData.genderPreference,
      move_in_date: profileData.moveInDate,
      lease_duration: profileData.leaseDuration,
      lifestyle: profileData.lifestyle,
      languages: profileData.languages || []
    };
    
    let result;
    
    // Insert or update profile
    if (!existingProfile) {
      // Create new profile
      result = await supabase
        .from('profiles')
        .insert(dbProfileData)
        .select();
        
      // Update user's profile_completed status
      await supabase
        .from('users')
        .update({ profile_completed: true })
        .eq('id', userId);
    } else {
      // Update existing profile
      result = await supabase
        .from('profiles')
        .update(dbProfileData)
        .eq('user_id', userId)
        .select();
    }
    
    if (result.error) throw result.error;
    
    // Get updated profile with formatted data
    return await getProfileByUserId(userId);
  } catch (error) {
    console.error('Update profile error:', error);
    return { profile: null, error };
  }
};

/**
 * Add or update profile pictures
 * @param {string} userId - User ID
 * @param {Object} pictureData - Picture data
 * @returns {Object} The added picture or error
 */
const addProfilePicture = async (userId, pictureData) => {
  try {
    // If marked as primary, set all other pictures as non-primary
    if (pictureData.isPrimary) {
      await supabase
        .from('profile_pictures')
        .update({ is_primary: false })
        .eq('user_id', userId);
    }
    
    // Add new picture
    const { data: picture, error } = await supabase
      .from('profile_pictures')
      .insert({
        user_id: userId,
        url: pictureData.url,
        is_primary: pictureData.isPrimary || false
      })
      .select()
      .single();
    
    if (error) throw error;
    
    // Format picture data for API response
    const formattedPicture = {
      id: picture.id,
      url: picture.url,
      isPrimary: picture.is_primary,
      uploadedAt: picture.uploaded_at
    };
    
    return { picture: formattedPicture, error: null };
  } catch (error) {
    console.error('Add profile picture error:', error);
    return { picture: null, error };
  }
};

/**
 * Delete a profile picture
 * @param {string} pictureId - Picture ID
 * @returns {Object} Success status or error
 */
const deleteProfilePicture = async (pictureId) => {
  try {
    const { error } = await supabase
      .from('profile_pictures')
      .delete()
      .eq('id', pictureId);
    
    if (error) throw error;
    
    return { success: true, error: null };
  } catch (error) {
    console.error('Delete profile picture error:', error);
    return { success: false, error };
  }
};

module.exports = {
  getProfileByUserId,
  createOrUpdateProfile,
  addProfilePicture,
  deleteProfilePicture
}; 