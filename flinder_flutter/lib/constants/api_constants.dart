class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://flinder-express-server.onrender.com';

  // Supabase Configuration
  static const String supabaseUrl = 'https://frjdhtasvvyutekzmfgb.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyamRodGFzdnZ5dXRla3ptZmdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2MjY3MTgsImV4cCI6MjA1OTIwMjcxOH0.cPjrAW1tXok0RQIWxCpjVJv1pryZ1OX-9YTrm8O9hxE';

  // Authentication Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String refreshTokenEndpoint = '/api/auth/refresh-token';

  // User Endpoints
  static const String userEndpoint = '/api/users';
  static const String userProfileEndpoint = '/api/users/profile';
  static const String userVerificationEndpoint = '/api/users/verification';

  // Profile & Preferences Endpoints
  static const String preferencesEndpoint = '/api/preferences';
  static const String profileEndpoint = '/api/profile/me';
  static const String profileMeEndpoint = '/api/profile/me';
  static const String updateBioEndpoint = '/api/profile/{userId}/bio';

  // Matching Endpoints
  static const String matchesEndpoint = '/api/discover/matches';
  static const String potentialMatchesEndpoint = '/api/matches/potential';
  static const String discoverEndpoint = '/api/discover';
  static const String likeEndpoint = '/api/matches/like';
  static const String dislikeEndpoint = '/api/matches/dislike';

  // Messaging Endpoints
  static const String conversationsEndpoint = '/api/conversations';
  static const String messagesEndpoint = '/api/messages';

  // Location & Search Endpoints
  static const String locationSearchEndpoint = '/api/location/search';
  static const String roomsSearchEndpoint = '/api/rooms/search';

  // Media Endpoints
  static const String mediaUploadEndpoint = '/api/media/upload';
  static const String mediaDeleteEndpoint = '/api/media/delete';
}
