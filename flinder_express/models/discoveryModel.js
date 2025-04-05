const supabase = require('../supabaseClient');
const Joi = require('joi');

/**
 * Get potential matches based on user preferences
 * @param {string} userId - User ID
 * @param {number} limit - Number of profiles to return
 * @param {number} offset - Pagination offset
 * @returns {Object} List of potential matches or error
 */
const getDiscoveryProfiles = async (userId, limit = 10, offset = 0) => {
  try {
    // First get the user's profile and preferences
    const { data: currentUserProfile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', userId)
      .single();
    
    if (profileError) {
      throw new Error('Failed to fetch user profile');
    }

    const { data: userPreferences, error: prefError } = await supabase
      .from('preferences')
      .select('*')
      .eq('user_id', userId)
      .single();
    
    if (prefError) {
      throw new Error('Failed to fetch user preferences');
    }

    if (!currentUserProfile || !userPreferences) {
      throw new Error('User profile or preferences not found');
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

    // Build the query based on preferences
    let query = supabase
      .from('profiles')
      .select(`
        *,
        users!profiles_user_id_fkey (
          id,
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
      .not('user_id', 'in', `(${excludeUserIds.join(',')})`)
      .limit(limit)
      .range(offset, offset + limit - 1);
    
    // Add critical filters if they exist
    if (userPreferences.critical) {
      const critical = userPreferences.critical;
      
      // Location filter - match city
      if (critical.location?.city) {
        query = query.eq('location->>city', critical.location.city);
      }
      
      // Budget filter - find users with budgets that overlap
      if (critical.budget) {
        const { min: minBudget, max: maxBudget } = critical.budget;
        query = query
          .lte('budget->>min', maxBudget)  // Their minimum is less than or equal to our maximum
          .gte('budget->>max', minBudget); // Their maximum is greater than or equal to our minimum
      }
      
      // Room preference filter
      if (critical.roomType && critical.roomType !== 'any') {
        query = query.eq('room_preference', critical.roomType);
      }
      
      // Gender preference filter
      if (critical.genderPreference === 'same_gender') {
        // First get users with the same gender
        const { data: userData, error: userError } = await supabase
          .from('users')
          .select('gender')
          .eq('id', userId)
          .single();
          
        if (userError) {
          throw new Error('Failed to fetch user gender');
        }

        if (userData?.gender) {
          query = query.eq('users.gender', userData.gender);
        }
      }
    }
    
    // Execute the query
    const { data: profiles, error: queryError, count } = await query;
    
    if (queryError) {
      throw queryError;
    }
    
    // Format the profiles for the API response
    const formattedProfiles = profiles.map(profile => {
      const pictures = profile.users?.profile_pictures || [];
      const primaryPicture = pictures.find(pic => pic.is_primary) || pictures[0];
      
      return {
        userId: profile.user_id,
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
        moveInDate: profile.move_in_date
      };
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
  getUserMatches
}; 