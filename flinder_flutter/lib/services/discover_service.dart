import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';
import '../models/discover_profile_model.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../main.dart' as app;

class DiscoverService {
  // Get Supabase client
  static final _supabase = Supabase.instance.client;

  // Ensure Supabase session is active
  static Future<bool> ensureSupabaseAuth() async {
    try {
      // Check if we have a token
      final token = await AuthService.getAuthToken();
      if (token == null) {
        log('No auth token available');
        return false;
      }

      // Check if Supabase is already authenticated
      final session = _supabase.auth.currentSession;
      if (session != null) {
        log('Supabase session is active');
        return true;
      }

      // Try to authenticate with Supabase using our token
      // Note: This is a custom approach - in a real app, Supabase would use JWT tokens
      // In this case, we're using a dummy login to get a session
      try {
        log('Attempting to authenticate with Supabase...');
        // Use the global supabase client from main.dart
        if (app.isSupabaseAvailable && app.supabaseClient != null) {
          // Try a direct anonymous sign-in
          final response = await app.supabaseClient!.auth.signInAnonymously();
          if (response.session != null) {
            log('Successfully created an anonymous Supabase session');
            return true;
          }
        }

        log('Failed to create Supabase session');
        return false;
      } catch (e) {
        log('Error authenticating with Supabase: $e');
        return false;
      }
    } catch (e) {
      log('Error ensuring Supabase auth: $e');
      return false;
    }
  }

  // Record a swipe in the database
  static Future<bool> recordSwipe({
    required String targetUserId,
    required String direction,
  }) async {
    try {
      // First ensure Supabase is authenticated
      final isAuth = await ensureSupabaseAuth();
      if (!isAuth) {
        log('Cannot record swipe: Failed to authenticate with Supabase');
      }

      // Get current user ID from our AuthService instead of Supabase directly
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        log('Cannot record swipe: No authenticated user found via AuthService');

        // Get current user ID from API token as fallback
        final token = await AuthService.getAuthToken();
        if (token == null) {
          log('Cannot record swipe: No auth token found');
          return false;
        }

        // Try to get user from Supabase session directly
        try {
          final session = _supabase.auth.currentSession;
          if (session != null) {
            final userId = session.user.id;
            log('Found user ID from Supabase session: $userId');
            return await _insertSwipeRecord(userId, targetUserId, direction);
          } else {
            log('No Supabase session found');
            // Try to insert with the token itself as last resort
            // This likely won't work but is for debugging purposes
            return await _insertSwipeRecord(token, targetUserId, direction);
          }
        } catch (e) {
          log('Error getting user from Supabase session: $e');
          return false;
        }
      }

      log('Found user via AuthService: ${user.id}');
      return await _insertSwipeRecord(user.id, targetUserId, direction);
    } catch (e) {
      log('Exception recording swipe: $e');
      return false;
    }
  }

  // Helper method to insert a swipe record
  static Future<bool> _insertSwipeRecord(
    String swiperId,
    String targetUserId,
    String direction,
  ) async {
    // Validate direction is either 'left' or 'right'
    if (direction != 'left' && direction != 'right') {
      log('Invalid swipe direction: $direction. Must be "left" or "right"');
      return false;
    }

    log(
      'Recording swipe in Supabase: $swiperId -> $targetUserId (direction: $direction)',
    );

    try {
      // Try multiple approaches to insert the swipe
      try {
        // 1. First attempt: Standard insert
        log('Attempting standard insert...');
        final response = await _supabase.from('swipes').insert({
          'swiper_id': swiperId,
          'target_user_id': targetUserId,
          'direction': direction,
        });

        log('Standard insert successful');
        return true;
      } catch (insertError) {
        log('Standard insert failed: $insertError');

        // 2. Second attempt: Direct SQL query
        try {
          log('Attempting direct SQL insert...');
          final result = await _supabase.rpc(
            'execute_sql',
            params: {
              'query': '''
              INSERT INTO swipes (swiper_id, target_user_id, direction)
              VALUES ('$swiperId', '$targetUserId', '$direction')
            ''',
            },
          );

          log('SQL insert completed');
          return true;
        } catch (sqlError) {
          log('SQL insert failed: $sqlError');

          // 3. Last attempt: Using REST to create a swipe via the API
          try {
            log('Attempting to insert via REST API...');
            final token = await AuthService.getAuthToken();
            if (token != null) {
              final response = await http.post(
                Uri.parse('${ApiConstants.baseUrl}/api/swipes'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': token,
                },
                body: jsonEncode({
                  'swiper_id': swiperId,
                  'target_user_id': targetUserId,
                  'direction': direction,
                }),
              );

              if (response.statusCode >= 200 && response.statusCode < 300) {
                log('REST API insert successful');
                return true;
              } else {
                log('REST API insert failed: ${response.body}');
              }
            }
          } catch (restError) {
            log('REST API insert failed: $restError');
          }

          // All attempts failed
          return false;
        }
      }
    } catch (dbError) {
      log('All database attempts failed: $dbError');
      return false;
    }
  }

  // Main method to get discover profiles
  static Future<List<UserProfile>> getDiscoverProfiles() async {
    try {
      // Check authentication
      final token = await AuthService.getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get IDs of users the current user has already swiped on
      final alreadySwipedUserIds = await _getAlreadySwipedUserIds();
      log('Filtered out ${alreadySwipedUserIds.length} already swiped users');

      // Step 1: Fetch profiles from the API endpoint
      final apiProfiles = await _fetchProfilesFromAPI(token);

      if (apiProfiles.isNotEmpty) {
        log('Successfully fetched ${apiProfiles.length} profiles from API');

        // Filter out already swiped users
        final filteredProfiles =
            apiProfiles.where((profile) {
              final profileUserId = profile['userId'] as String;
              return !alreadySwipedUserIds.contains(profileUserId);
            }).toList();

        log('After filtering: ${filteredProfiles.length} profiles remaining');

        // Step 2: Enrich with user data from Supabase
        final enrichedProfiles = await _enrichProfilesWithUserData(
          filteredProfiles,
        );

        return enrichedProfiles;
      }

      // If API call fails, return dummy profiles
      log('No profiles found from API, returning dummy profiles');
      return UserProfile.getDummyProfiles();
    } catch (e) {
      log('Error in getDiscoverProfiles: $e');
      return UserProfile.getDummyProfiles();
    }
  }

  // Get list of user IDs that the current user has already swiped on (either left or right)
  static Future<Set<String>> _getAlreadySwipedUserIds() async {
    try {
      // Ensure Supabase is authenticated
      await ensureSupabaseAuth();

      // Get current user ID
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        log('Cannot get swiped users: No authenticated user');
        return {};
      }

      // Query the swipes table for all entries where current user is the swiper_id
      try {
        final response = await _supabase
            .from('swipes')
            .select('target_user_id')
            .eq('swiper_id', currentUser.id);

        if (response != null && response.isNotEmpty) {
          // Extract target user IDs from the response
          final swipedUserIds =
              response
                  .map<String>((swipe) => swipe['target_user_id'] as String)
                  .toSet();
          log(
            'Found ${swipedUserIds.length} users that the current user has already swiped on',
          );
          return swipedUserIds;
        } else {
          log('No previous swipes found for this user');
          return {};
        }
      } catch (e) {
        log('Error fetching swiped users from database: $e');
        return {};
      }
    } catch (e) {
      log('Exception getting swiped users: $e');
      return {};
    }
  }

  // Step 1: Fetch profiles from the API
  static Future<List<dynamic>> _fetchProfilesFromAPI(String token) async {
    try {
      final endpoint =
          '${ApiConstants.baseUrl}${ApiConstants.discoverEndpoint}';
      log('API Call: GET $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        log('API returned success: ${responseData['success']}');

        if (responseData['success'] == true &&
            responseData['profiles'] != null) {
          final List<dynamic> profiles = responseData['profiles'];
          log('Fetched ${profiles.length} profiles from API');
          return profiles;
        }
      }

      log('API call failed or returned no profiles');
      return [];
    } catch (e) {
      log('Error fetching profiles from API: $e');
      return [];
    }
  }

  // Step 2: Enrich API profiles with Supabase user data
  static Future<List<UserProfile>> _enrichProfilesWithUserData(
    List<dynamic> apiProfiles,
  ) async {
    List<UserProfile> enrichedProfiles = [];

    for (var apiProfile in apiProfiles) {
      try {
        final String userId = apiProfile['userId'];
        log('Processing API profile with userId: $userId');

        // Fetch user details from Supabase
        final userData = await _fetchUserById(userId);

        if (userData != null) {
          log('Found corresponding user in Supabase: ${userData['name']}');

          // Combine API profile with Supabase user data
          final combinedData = <String, dynamic>{
            ...Map<String, dynamic>.from(apiProfile),
            'name': userData['name'],
            'email': userData['email'],
            'date_of_birth': userData['date_of_birth'],
            'gender': userData['gender'],
            'user_id': userData['user_id'],
            'last_active': userData['last_active'],
            'online_status': userData['online_status'],
          };

          // Convert to UserProfile
          final userProfile =
              DiscoverProfileModel.fromJson(combinedData).toUserProfile();
          log('Created profile for ${userProfile.name}');
          enrichedProfiles.add(userProfile);
        } else {
          log('No Supabase user found for ID: $userId, using API data only');
          // If no user data found, still create profile with API data
          final userProfile =
              DiscoverProfileModel.fromJson(apiProfile).toUserProfile();
          enrichedProfiles.add(userProfile);
        }
      } catch (e) {
        log('Error processing profile: $e');
        // On error, try to create profile with available data
        try {
          final userProfile =
              DiscoverProfileModel.fromJson(apiProfile).toUserProfile();
          enrichedProfiles.add(userProfile);
        } catch (e2) {
          log('Failed to create profile from API data: $e2');
        }
      }
    }

    log('Returning ${enrichedProfiles.length} enriched profiles');
    return enrichedProfiles;
  }

  // Helper to fetch a single user from Supabase by UUID
  static Future<Map<String, dynamic>?> _fetchUserById(String userId) async {
    try {
      log('Fetching user data from Supabase for ID: $userId');

      final response =
          await _supabase
              .from('users')
              .select('''
            id, 
            name, 
            email, 
            phone, 
            date_of_birth, 
            gender, 
            user_id, 
            last_active, 
            online_status
          ''')
              .eq('id', userId)
              .maybeSingle();

      if (response != null) {
        log('Found user in Supabase: ${response['name']}');
        return response;
      } else {
        log('User not found in Supabase for ID: $userId');
        return null;
      }
    } catch (e) {
      log('Error fetching user from Supabase: $e');
      return null;
    }
  }

  // Fetch users who liked the current user (swiper_id -> current user as target)
  static Future<List<UserProfile>> getLikesReceived() async {
    try {
      // Ensure we're authenticated
      await ensureSupabaseAuth();

      // Get current user ID
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        log('Cannot get likes: No authenticated user');
        return [];
      }

      log('Fetching users who liked user ID: ${currentUser.id}');

      // Query the swipes table for entries where current user is the target_user_id
      // and direction is 'left' (like)
      try {
        final response = await _supabase
            .from('swipes')
            .select('''
              id,
              swiper_id,
              created_at,
              users:swiper_id(
                id,
                name,
                email,
                date_of_birth,
                gender,
                user_id,
                last_active,
                online_status,
                phone
              )
            ''')
            .eq('target_user_id', currentUser.id)
            .eq('direction', 'left')
            .order('created_at', ascending: false);

        log('Found ${response.length} likes');

        // Extract user data and convert to UserProfile objects
        List<UserProfile> likedByUsers = [];

        for (var swipe in response) {
          try {
            if (swipe['users'] != null) {
              // Get user data from the swipe record
              final userData = swipe['users'];

              // Add swipe ID to track this specific like
              userData['swipeId'] = swipe['id'];

              // Fetch additional profile data for this user
              final userProfileData = await _fetchUserById(userData['id']);

              // Create a combined data object
              final Map<String, dynamic> combinedData = {
                ...userData,
                // Add swipe-specific data
                'swipeId': swipe['id'],
                'liked_at': swipe['created_at'],
              };

              // Convert to UserProfile
              final userProfile = await _createProfileFromUserData(
                combinedData,
              );
              likedByUsers.add(userProfile);
            }
          } catch (e) {
            log('Error processing like data: $e');
          }
        }

        return likedByUsers;
      } catch (e) {
        log('Error fetching likes from database: $e');
        return [];
      }
    } catch (e) {
      log('Exception getting likes: $e');
      return [];
    }
  }

  // Handle the current user's response to a like (accept or decline)
  static Future<bool> respondToLike({
    required String likeId, // The ID of the swipe record
    required String userId, // The ID of the user who liked the current user
    required bool isAccepted, // true = accept/like back, false = decline
  }) async {
    try {
      // Ensure we're authenticated
      await ensureSupabaseAuth();

      // Get current user ID
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        log('Cannot respond to like: No authenticated user');
        return false;
      }

      if (isAccepted) {
        // ACCEPT: Create a reciprocal swipe record (current user likes the user back)
        log(
          'Accepting like from user $userId (current user: ${currentUser.id})',
        );

        final success = await _insertSwipeRecord(
          currentUser.id,
          userId,
          'left', // left = like
        );

        if (!success) {
          log('Failed to create reciprocal like record');
          return false;
        }

        log('Successfully created reciprocal like record');
        return true;
      } else {
        // DECLINE: Delete the swipe record
        log('Declining like from user $userId (swipe ID: $likeId)');

        try {
          // Delete the swipe record
          await _supabase.from('swipes').delete().eq('id', likeId);

          log('Successfully deleted swipe record');
          return true;
        } catch (e) {
          log('Error deleting swipe record: $e');
          return false;
        }
      }
    } catch (e) {
      log('Exception responding to like: $e');
      return false;
    }
  }

  // Helper method to create a UserProfile from user data
  static Future<UserProfile> _createProfileFromUserData(
    Map<String, dynamic> userData,
  ) async {
    try {
      // Calculate age from date of birth
      int age = 0;
      if (userData['date_of_birth'] != null) {
        try {
          final birthDate = DateTime.parse(
            userData['date_of_birth'].toString(),
          );
          age = DateTime.now().difference(birthDate).inDays ~/ 365;
        } catch (e) {
          log('Error calculating age: $e');
        }
      }

      // Fetch profile data for this user if available
      Map<String, dynamic> profileData = {};
      try {
        final profileResponse =
            await _supabase
                .from('profiles')
                .select('''
              bio,
              interests,
              location:locations(city, neighborhood),
              lifestyle:lifestyles(*)
            ''')
                .eq('user_id', userData['id'])
                .maybeSingle();

        if (profileResponse != null) {
          profileData = profileResponse;
        }
      } catch (e) {
        log('Error fetching profile data: $e');
      }

      // Fetch profile pictures if available
      List<Map<String, dynamic>> pictureData = [];
      try {
        final pictureResponse = await _supabase
            .from('profile_pictures')
            .select('id, url, is_primary')
            .eq('user_id', userData['id']);

        if (pictureResponse != null && pictureResponse.isNotEmpty) {
          pictureData = List<Map<String, dynamic>>.from(pictureResponse);
        }
      } catch (e) {
        log('Error fetching profile pictures: $e');
      }

      // Create a combined data object for the DiscoverProfileModel
      final combinedData = {
        'id': userData['id'],
        'userId': userData['id'],
        'name': userData['name'] ?? 'Unknown',
        'email': userData['email'] ?? '',
        'phone': userData['phone'],
        'date_of_birth': userData['date_of_birth'],
        'gender': userData['gender'] ?? 'other',
        'user_id': userData['user_id'],
        'last_active': userData['last_active'],
        'online_status': userData['online_status'],
        'swipeId': userData['swipeId'],
        'liked_at': userData['liked_at'],
        'age': age,
        'bio': profileData['bio'],
        'interests': profileData['interests'],
        'location':
            profileData['location'] != null &&
                    profileData['location'].isNotEmpty
                ? profileData['location'][0]
                : {'city': 'Unknown'},
        'lifestyle':
            profileData['lifestyle'] != null &&
                    profileData['lifestyle'].isNotEmpty
                ? profileData['lifestyle'][0]
                : {},
        'profilePictures': pictureData,
      };

      // Convert to UserProfile via DiscoverProfileModel
      final profile =
          DiscoverProfileModel.fromJson(combinedData).toUserProfile();

      // Add extra data to preferences
      if (profile.preferences != null) {
        profile.preferences!['swipeId'] = userData['swipeId'];
        profile.preferences!['liked_at'] = userData['liked_at'];
      }

      return profile;
    } catch (e) {
      log('Error creating profile from user data: $e');

      // Create a minimal profile as fallback
      return UserProfile(
        id: userData['id'] ?? 'unknown',
        name: userData['name'] ?? 'Unknown User',
        age: 0,
        location: 'Unknown',
        roomType: 'Any',
        budget: 'Flexible',
        preferences: {
          'swipeId': userData['swipeId'],
          'liked_at': userData['liked_at'],
        },
      );
    }
  }
}
