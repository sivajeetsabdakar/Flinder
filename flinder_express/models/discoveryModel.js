const supabase = require('../supabaseClient');
const Joi = require('joi');
const axios = require('axios');

// Get ML server URL from environment variables
const ML_SERVER_URL = process.env.ML_SERVER_URL || 'http://localhost:5000';

/**
 * Check if the ML server is available
 * @returns {Promise<boolean>} True if server is available
 */
const checkMLServerHealth = async () => {
  try {
    const response = await axios.get(`${ML_SERVER_URL}/api/health`, { timeout: 5000 });
    return response.status === 200;
  } catch (error) {
    console.error('ML server health check failed:', error.message);
    return false;
  }
};

/**
 * Get potential matches based on user preferences
 * @param {string} userId - User ID
 * @param {number} limit - Number of profiles to return
 * @param {number} offset - Pagination offset
 * @returns {Object} List of potential matches or error
 */
const getDiscoveryProfiles = async (userId, limit = 10, offset = 0) => {
  try {
    // First get the user's preferences to get the city filter
    const { data: userPreferences, error: prefError } = await supabase
      .from('preferences')
      .select('critical')
      .eq('user_id', userId)
      .single();
    
    if (prefError) {
      throw new Error('Failed to fetch user preferences');
    }

    if (!userPreferences?.critical?.location?.city) {
      throw new Error('User city preference not set');
    }

    // Get users already swiped on
    const { data: swipedUsers, error: swipeError } = await supabase
      .from('swipes')
      .select('target_user_id')
      .eq('swiper_id', userId);
    
    if (swipeError) {
      throw new Error('Failed to fetch swiped users');
    }

    const swipedUserIds = swipedUsers?.map(swipe => swipe.target_user_id) || [];
    const excludeUserIds = [...swipedUserIds, userId];

    // Get current user's info
    const { data: currentUser, error: currentUserError } = await supabase
      .from('users')
      .select('id, user_id')
      .eq('id', userId)
      .single();
    
    if (currentUserError) {
      throw new Error('Failed to fetch current user info');
    }

    // Get profiles filtered only by city
    const { data: profiles, error: queryError, count } = await supabase
      .from('profiles')
      .select(`
        *,
        users!profiles_user_id_fkey (
          id,
          user_id,
          name,
          gender,
          profile_pictures (
            id,
            url,
            is_primary,
            uploaded_at
          )
        )
      `)
      .eq('location->>city', userPreferences.critical.location.city.toLowerCase())
      .not('user_id', 'in', `(${excludeUserIds.join(',')})`)
      .limit(limit)
      .range(offset, offset + limit - 1);
    
    if (queryError) {
      throw queryError;
    }

    // Get ML matches if we have profiles
    let mlMatches = [];
    if (profiles.length > 0) {
      try {
        // Check ML server health first
        const isMLServerHealthy = await checkMLServerHealth();
        if (!isMLServerHealthy) {
          console.warn('ML server is not available, using default match probabilities');
          throw new Error('ML server is not available');
        }

        // Create array of numeric user_ids for ML matching
        const filteredUserIds = profiles.map(profile => profile.users.user_id);
        
        // Prepare ML request payload
        const mlRequestData = {
          current_user_id: currentUser.user_id,
          filtered_user_ids: filteredUserIds
        };
        
        console.log('ML Request:', JSON.stringify(mlRequestData, null, 2));
        
        // Call ML service
        const mlResponse = await axios.post(`${ML_SERVER_URL}/api/batch-match`, mlRequestData);
        console.log('ML Response Status:', mlResponse.status);
        console.log('ML Response Headers:', JSON.stringify(mlResponse.headers, null, 2));
        console.log('ML Response Data:', JSON.stringify(mlResponse.data, null, 2));
        
        if (!mlResponse.data || !Array.isArray(mlResponse.data.matches)) {
          console.error('Invalid ML response format:', mlResponse.data);
          throw new Error('Invalid ML response format');
        }
        
        mlMatches = mlResponse.data.matches || [];
        console.log(`Processed ${mlMatches.length} ML matches`);
        
        // Verify match structure
        if (mlMatches.length > 0) {
          console.log('Sample match data:', JSON.stringify(mlMatches[0], null, 2));
          
          // Verify user_id mapping
          const profileIds = profiles.map(p => p.users.user_id);
          const matchIds = mlMatches.map(m => m.user_id);
          const unmatchedIds = profileIds.filter(id => !matchIds.includes(id));
          
          if (unmatchedIds.length > 0) {
            console.warn('Some profiles have no ML match:', unmatchedIds);
          }
        }
      } catch (error) {
        console.error('ML matching service error:', error.message);
        if (error.response) {
          console.error('ML error response:', {
            status: error.response.status,
            headers: error.response.headers,
            data: error.response.data
          });
        } else if (error.request) {
          console.error('ML error request sent but no response received');
        }
        
        // If ML service fails, use default 50% match for all profiles
        mlMatches = profiles.map(profile => ({
          user_id: profile.users.user_id,
          similarity: 0.5,
          match_probability: 50.0,
          interpretation: "Default match probability (ML service unavailable)"
        }));
      }
    }
    
    // Format the profiles for the API response with ML match data
    const formattedProfiles = profiles.map(profile => {
      const pictures = profile.users?.profile_pictures || [];
      const primaryPicture = pictures.find(pic => pic.is_primary) || pictures[0];
      
      try {
        // Find matching ML data for this profile using numeric user_id
        const mlMatch = mlMatches.find(match => {
          // If ML match user_id is not a number but profiles use numbers, try converting
          if (typeof match.user_id !== 'number' && !isNaN(match.user_id)) {
            return parseInt(match.user_id, 10) === profile.users.user_id;
          }
          return match.user_id === profile.users.user_id;
        });
        
        if (!mlMatch) {
          console.warn(`No ML match found for user_id ${profile.users.user_id}`);
        }
        
        // Only use default values if no ML match was found
        const matchData = mlMatch || {
          similarity: 0.5,
          match_probability: 50.0,
          interpretation: "Default match probability"
        };
        
        // Validate match data structure
        if (mlMatch && (
          typeof matchData.similarity === 'undefined' || 
          typeof matchData.match_probability === 'undefined' || 
          typeof matchData.interpretation === 'undefined'
        )) {
          console.warn('Incomplete ML match data for user_id:', profile.users.user_id, matchData);
        }
        
        return {
          userId: profile.users.id, // Return UUID for API
          name: profile.users?.name,
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
          lifestyle: profile.lifestyle,
          budget: profile.budget,
          roomPreference: profile.room_preference,
          moveInDate: profile.move_in_date,
          similarity: matchData.similarity,
          matchProbability: matchData.match_probability,
          matchInterpretation: matchData.interpretation
        };
      } catch (err) {
        console.error('Error processing ML match for profile:', profile.users.user_id, err);
        // Return profile with default match data on error
        return {
          userId: profile.users.id,
          name: profile.users?.name,
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
          lifestyle: profile.lifestyle,
          budget: profile.budget,
          roomPreference: profile.room_preference,
          moveInDate: profile.move_in_date,
          similarity: 0.5,
          matchProbability: 50.0,
          matchInterpretation: "Error processing match data"
        };
      }
    });
    
    return {
      profiles: formattedProfiles,
      pagination: {
        total: count || formattedProfiles.length,
        limit,
        offset,
        hasMore: (count || formattedProfiles.length) > offset + limit
      },
      error: null
    };

  } catch (error) {
    return { 
      profiles: [], 
      pagination: { total: 0, limit, offset, hasMore: false }, 
      error: {
        message: error.message,
        code: error.code
      }
    };
  }
};

/**
 * Record a swipe action
 * @param {string} swiperId - Swiper user ID
 * @param {string} targetUserId - Target user ID
 * @param {string} direction - Swipe direction ('left' or 'right')
 * @returns {Object} Swipe result with match information if applicable
 */
const recordSwipe = async (swiperId, targetUserId, direction) => {
  try {
    // Verify both users exist
    const { data: users, error: userError } = await supabase
      .from('users')
      .select('id')
      .in('id', [swiperId, targetUserId]);

    if (userError || users.length !== 2) {
      throw new Error('Invalid user IDs');
    }

    // Check for existing swipe
    const { data: existingSwipe } = await supabase
      .from('swipes')
      .select('*')
      .eq('swiper_id', swiperId)
      .eq('target_user_id', targetUserId)
      .single();

    if (existingSwipe) {
      throw new Error('User already swiped on this profile');
    }

    // Insert the swipe record
    const { data: swipe, error: swipeError } = await supabase
      .from('swipes')
      .insert({
        swiper_id: swiperId,
        target_user_id: targetUserId,
        direction
      })
      .select()
      .single();
    
    if (swipeError) {
      throw swipeError;
    }
    
    // If it's a right swipe, check for a match
    if (direction === 'right') {
      const { data: matchingSwipe, error: matchSwipeError } = await supabase
        .from('swipes')
        .select('*')
        .eq('swiper_id', targetUserId)
        .eq('target_user_id', swiperId)
        .eq('direction', 'right')
        .single();
      
      if (matchSwipeError && matchSwipeError.code !== 'PGRST116') {
        throw matchSwipeError;
      }

      // If there's a matching swipe, create a match
      if (matchingSwipe) {
        // Create a match record
        const { data: match, error: matchError } = await supabase
          .from('matches')
          .insert({
            user1_id: swiperId,
            user2_id: targetUserId
          })
          .select()
          .single();
        
        if (matchError) {
          throw matchError;
        }
        
        // Create a conversation
        const { data: conversation, error: convError } = await supabase
          .from('conversations')
          .insert({
            match_id: match.id,
            participants: [swiperId, targetUserId]
          })
          .select()
          .single();
        
        if (convError) {
          throw convError;
        }
        
        // Create notifications
        await supabase
          .from('notifications')
          .insert([
            {
              user_id: swiperId,
              type: 'match',
              title: 'New Match!',
              body: 'You have a new roommate match!'
            },
            {
              user_id: targetUserId,
              type: 'match',
              title: 'New Match!',
              body: 'You have a new roommate match!'
            }
          ]);

        return {
          success: true,
          match: true,
          matchDetails: {
            id: match.id,
            user1Id: match.user1_id,
            user2Id: match.user2_id,
            createdAt: match.created_at,
            conversationId: conversation.id
          },
          error: null
        };
      }
    }
    
    return {
      success: true,
      match: false,
      error: null
    };

  } catch (error) {
    return { 
      success: false, 
      match: false, 
      error: {
        message: error.message,
        code: error.code
      }
    };
  }
};

/**
 * Get user matches
 * @param {string} userId - User ID
 * @returns {Object} List of matches or error
 */
const getUserMatches = async (userId) => {
  try {
    // Get all matches where the user is either user1 or user2
    const { data: matches, error: matchError } = await supabase
      .from('matches')
      .select(`
        *,
        user1:user1_id (id, name, profile:profiles(bio, profile_pictures(url, is_primary))),
        user2:user2_id (id, name, profile:profiles(bio, profile_pictures(url, is_primary))),
        conversations (id, last_message_at)
      `)
      .or(`user1_id.eq.${userId},user2_id.eq.${userId}`);
    
    if (matchError) {
      throw matchError;
    }
    
    // Format the matches for API response
    const formattedMatches = matches.map(match => {
      const otherUser = match.user1_id === userId ? match.user2 : match.user1;
      const otherUserProfile = otherUser?.profile?.[0];
      const profilePicture = otherUserProfile?.profile_pictures?.find(pic => pic.is_primary) 
                           || otherUserProfile?.profile_pictures?.[0];

      return {
        id: match.id,
        matchedUserId: otherUser?.id,
        matchedUserName: otherUser?.name,
        matchedUserBio: otherUserProfile?.bio,
        matchedUserPhoto: profilePicture?.url,
        conversationId: match.conversations?.[0]?.id,
        lastMessageAt: match.conversations?.[0]?.last_message_at,
        createdAt: match.created_at
      };
    });
    
    return { matches: formattedMatches, error: null };

  } catch (error) {
    return { 
      matches: [], 
      error: {
        message: error.message,
        code: error.code
      }
    };
  }
};

// Validation schemas
const swipeSchema = Joi.object({
  targetUserId: Joi.string().required(),
  direction: Joi.string().valid('left', 'right').required()
});

// Add request logging middleware
const logRequest = (req, res, next) => {
  console.log('Discovery API Request:', {
    method: req.method,
    path: req.path,
    query: req.query,
    body: req.body,
    userId: req.user?.id,
    timestamp: new Date().toISOString()
  });
  next();
};

module.exports = {
  getDiscoveryProfiles,
  recordSwipe,
  getUserMatches,
  checkMLServerHealth
}; 