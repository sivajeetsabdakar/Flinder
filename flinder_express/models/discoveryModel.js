const supabase = require('../supabaseClient');

/**
 * Get potential roommate matches based on user preferences
 * @param {string} userId - User ID
 * @param {number} limit - Number of profiles to return (pagination)
 * @param {number} offset - Offset for pagination
 * @returns {Object} Preferences and pagination info or error
 */
const getDiscoveryProfiles = async (userId, limit = 10, offset = 0) => {
  try {
    // Get current user's preferences to find their city
    const { data: userPreference, error: userPrefError } = await supabase
      .from('preferences')
      .select('critical')
      .eq('user_id', userId)
      .single();
      
    if (userPrefError) throw userPrefError;
    
    // Extract city from user preferences
    const userCity = userPreference?.critical?.location?.city;
    console.log('User city:', userCity);
    
    if (!userCity) {
      return { 
        profiles: [], 
        pagination: { total: 0, limit, offset, hasMore: false },
        error: new Error('User preferences not set or missing city preference') 
      };
    }

    // Get ALL other users' preferences (no SQL filtering by city)
    const { data: allPreferences, error } = await supabase
      .from('preferences')
      .select(`
        id,
        user_id,
        critical,
        non_critical,
        discovery_settings,
        interests,
        users:user_id (id, email, name)
      `)
      .neq('user_id', userId); // Only exclude current user
      
    if (error) throw error;
    
    console.log(`Retrieved ${allPreferences.length} total preferences`);
    
    // Filter preferences by city in JavaScript
    const filteredPreferences = allPreferences.filter(pref => {
      const prefCity = pref.critical?.location?.city;
      console.log(`Checking user ${pref.user_id} with city: ${prefCity}`);
      return prefCity === userCity;
    });
    
    console.log(`Filtered to ${filteredPreferences.length} matching preferences by city: ${userCity}`);
    
    // Apply pagination in JavaScript
    const total = filteredPreferences.length;
    const paginatedPreferences = filteredPreferences.slice(offset, offset + limit);
    
    // Format preferences for API response
    const formattedProfiles = paginatedPreferences.map(pref => {
      return {
        userId: pref.user_id,
        bio: pref.critical?.roomType || "", // Using roomType as stand-in for bio
        generatedDescription: `User looking for housing in ${pref.critical?.location?.city || "unknown location"}`,
        interests: pref.interests || [],
        profilePictures: [
          {
            id: "placeholder",
            url: "https://via.placeholder.com/150",
            isPrimary: true,
            uploadedAt: new Date().toISOString()
          }
        ],
        location: pref.critical?.location || { city: "Unknown" },
        lifestyle: {
          schedule: pref.non_critical?.schedule || "unknown",
          cleaningHabits: pref.non_critical?.cleaningHabits || "unknown"
        }
      };
    });
    
    // Create pagination info
    const pagination = {
      total,
      limit,
      offset,
      hasMore: (offset + limit) < total
    };
    
    return { profiles: formattedProfiles, pagination, error: null };
  } catch (error) {
    console.error('Discovery profiles error:', error);
    return { 
      profiles: [], 
      pagination: { total: 0, limit, offset, hasMore: false },
      error 
    };
  }
};

/**
 * Record a swipe action
 * @param {string} userId - User ID
 * @param {string} targetUserId - Target user ID 
 * @param {string} action - 'like' or 'pass'
 * @returns {Object} Result of the swipe action
 */
const recordSwipe = async (userId, targetUserId, action) => {
  try {
    // Record the swipe
    const { data, error } = await supabase
      .from('swipes')
      .insert({
        user_id: userId,
        target_user_id: targetUserId,
        action
      })
      .select();
      
    if (error) throw error;
    
    // Check if this created a match (both users liked each other)
    let match = null;
    
    if (action === 'like') {
      // Check if target user has already liked this user
      const { data: matchData, error: matchError } = await supabase
        .from('swipes')
        .select('*')
        .eq('user_id', targetUserId)
        .eq('target_user_id', userId)
        .eq('action', 'like')
        .single();
        
      if (matchError && matchError.code !== 'PGRST116') {
        // PGRST116 is the error code for "no rows returned" which is expected if no match
        throw matchError;
      }
      
      if (matchData) {
        // This is a match! Create a match record
        const { data: newMatch, error: createMatchError } = await supabase
          .from('matches')
          .insert({
            user_id_1: userId,
            user_id_2: targetUserId,
            matched_at: new Date().toISOString()
          })
          .select()
          .single();
          
        if (createMatchError) throw createMatchError;
        
        match = {
          matchId: newMatch.id,
          userId: targetUserId,
          matchedAt: newMatch.matched_at
        };
      }
    }
    
    return { success: true, match, error: null };
  } catch (error) {
    console.error('Record swipe error:', error);
    return { success: false, match: null, error };
  }
};

/**
 * Get all matches for a user
 * @param {string} userId - User ID
 * @returns {Object} List of matches
 */
const getUserMatches = async (userId) => {
  try {
    // Query all matches where the user is involved
    const { data, error } = await supabase
      .from('matches')
      .select(`
        id, 
        matched_at,
        user_id_1,
        user_id_2,
        users1:user_id_1(id, email, name),
        users2:user_id_2(id, email, name)
      `)
      .or(`user_id_1.eq.${userId},user_id_2.eq.${userId}`)
      .order('matched_at', { ascending: false });
      
    if (error) throw error;
    
    // Format the matches
    const matches = data.map(match => {
      // Determine which user is the match (not the current user)
      const isUser1 = match.user_id_1 === userId;
      const matchUserId = isUser1 ? match.user_id_2 : match.user_id_1;
      const matchUser = isUser1 ? match.users2 : match.users1;
      
      return {
        matchId: match.id,
        userId: matchUserId,
        name: matchUser.name,
        email: matchUser.email,
        matchedAt: match.matched_at
      };
    });
    
    return { matches, error: null };
  } catch (error) {
    console.error('Get user matches error:', error);
    return { matches: [], error };
  }
};

module.exports = {
  getDiscoveryProfiles,
  recordSwipe,
  getUserMatches
};
