class ApiConstants {
  // Base URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static const bool allowDummyFallback = bool.fromEnvironment(
    'ALLOW_DUMMY_FALLBACK',
    defaultValue: false,
  );

  // Authentication Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String googleAuthEndpoint = '/api/auth/google';
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
  static const String potentialMatchesEndpoint = '/api/discover';
  static const String discoverEndpoint = '/api/discover';
  static const String likeEndpoint = '/api/discover/swipe';
  static const String dislikeEndpoint = '/api/discover/swipe';

  // Messaging Endpoints
  static const String conversationsEndpoint = '/api/conversations';
  static const String messagesEndpoint = '/api/messages';
  static const String notificationsEndpoint = '/api/notifications';
  static const String devicesEndpoint = '/api/devices';

  // Location & Search Endpoints
  static const String locationSearchEndpoint = '/api/location/search';
  static const String roomsSearchEndpoint = '/api/rooms/search';

  // Media Endpoints
  static const String mediaUploadEndpoint = '/api/profile/photos/upload';
  static const String mediaDeleteEndpoint = '/api/media/delete';

  // Safety & premium-feel endpoints
  static const String reportsEndpoint = '/api/reports';
  static const String flatReportsEndpoint = '/api/flat-reports';
  static const String blocksEndpoint = '/api/blocks';
  static const String swipeRewindEndpoint = '/api/swipes/rewind';
  static const String profileBoostEndpoint = '/api/profile/boost';
}
