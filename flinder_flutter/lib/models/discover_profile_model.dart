import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class DiscoverProfileModel {
  final String userId;
  final String? bio;
  final List<String>? interests;
  final List<ProfilePictureModel> profilePictures;
  final LocationModel location;
  final LifestyleModel lifestyle;
  final String name;
  final int age;
  final String? budget;
  final String? roomType;
  final String? moveInDate;
  final String? generatedDescription;

  // Additional user fields from Supabase
  final String email;
  final String? phone;
  final String gender;
  final bool profileCompleted;
  final DateTime? lastActive;
  final bool isOnline;
  final int? userIdNumber; // The user_id integer field

  DiscoverProfileModel({
    required this.userId,
    this.bio,
    this.interests,
    required this.profilePictures,
    required this.location,
    required this.lifestyle,
    required this.name,
    required this.age,
    this.budget,
    this.roomType,
    this.moveInDate,
    this.generatedDescription,
    required this.email,
    this.phone,
    required this.gender,
    required this.profileCompleted,
    this.lastActive,
    required this.isOnline,
    this.userIdNumber,
  });

  factory DiscoverProfileModel.fromJson(Map<String, dynamic> json) {
    // Debug the JSON input
    print(
      'Creating DiscoverProfileModel from JSON: userId=${json['userId']} or id=${json['id']}',
    );

    // Calculate age from date_of_birth if available
    int calculatedAge = 0;
    if (json['date_of_birth'] != null) {
      try {
        final birthDate = DateTime.parse(json['date_of_birth'].toString());
        calculatedAge = DateTime.now().difference(birthDate).inDays ~/ 365;
      } catch (e) {
        print('Error calculating age: $e');
      }
    }

    // Extract user_id number for display
    int? userIdNumber;
    if (json['user_id'] != null) {
      if (json['user_id'] is int) {
        userIdNumber = json['user_id'] as int;
      } else if (json['user_id'] is String) {
        userIdNumber = int.tryParse(json['user_id'].toString());
      }
    }

    // Get the UUID, preferring userId from API then id from Supabase
    final userId = json['userId'] ?? json['id'] ?? '';

    // Get the name from Supabase user data if available, otherwise use a fallback
    final name =
        json['name'] != null && json['name'].toString().trim().isNotEmpty
            ? json['name'].toString()
            : userIdNumber != null
            ? 'User #$userIdNumber'
            : 'Unknown';

    // Handle profile pictures from multiple formats
    List<ProfilePictureModel> profilePictures = [];
    if (json['profilePictures'] != null) {
      try {
        var picList = json['profilePictures'];
        if (picList is List) {
          profilePictures =
              picList
                  .map(
                    (x) =>
                        ProfilePictureModel.fromJson(x as Map<String, dynamic>),
                  )
                  .toList();
        }
      } catch (e) {
        print('Error parsing profile pictures: $e');
      }
    }

    return DiscoverProfileModel(
      userId: userId.toString(),
      bio: json['bio'] as String?,
      interests:
          json['interests'] != null ? _parseInterests(json['interests']) : null,
      profilePictures: profilePictures,
      location: LocationModel.fromJson(_getLocationJson(json)),
      lifestyle: LifestyleModel.fromJson(_getLifestyleJson(json)),
      name: name,
      age:
          json['age'] != null
              ? int.tryParse(json['age'].toString()) ?? calculatedAge
              : calculatedAge,
      budget: json['budget'] as String?,
      roomType: json['roomType'] as String?,
      moveInDate: json['moveInDate'] as String?,
      generatedDescription: json['generatedDescription'] as String?,
      email: json['email']?.toString() ?? '',
      phone: json['phone'] as String?,
      gender: json['gender']?.toString() ?? 'other',
      profileCompleted: json['profile_completed'] == true,
      lastActive:
          json['last_active'] != null
              ? _parseDateTime(json['last_active'].toString())
              : null,
      isOnline: json['online_status']?.toString() == 'online',
      userIdNumber: userIdNumber,
    );
  }

  // Parse interests from different formats
  static List<String> _parseInterests(dynamic interests) {
    if (interests is List) {
      return interests.map((e) => e.toString()).toList();
    } else if (interests is String) {
      return interests.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  // Parse DateTime safely
  static DateTime? _parseDateTime(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  // Extract location JSON from different formats
  static Map<String, dynamic> _getLocationJson(Map<String, dynamic> json) {
    if (json['location'] is Map) {
      return Map<String, dynamic>.from(json['location'] as Map);
    }
    return {'city': 'Unknown'};
  }

  // Extract lifestyle JSON from different formats
  static Map<String, dynamic> _getLifestyleJson(Map<String, dynamic> json) {
    if (json['lifestyle'] is Map) {
      return Map<String, dynamic>.from(json['lifestyle'] as Map);
    }
    return {};
  }

  // Helper method to get the name or a fallback
  String getName() {
    if (name.isNotEmpty && name != 'Unknown') {
      return name;
    }

    if (userIdNumber != null) {
      return 'User #$userIdNumber';
    }

    return 'Unknown User';
  }

  // Convert to UserProfile for compatibility with the existing SwipeCard widget
  UserProfile toUserProfile() {
    final primaryPicture =
        profilePictures.isNotEmpty
            ? profilePictures
                .firstWhere(
                  (pic) => pic.isPrimary,
                  orElse: () => profilePictures.first,
                )
                .url
            : null;

    // Create additional information to display on profile
    Map<String, dynamic> additionalInfo = {
      'Gender': gender,
      'Last active':
          lastActive != null ? _formatLastActive(lastActive!) : 'Unknown',
      'Online': isOnline ? 'Yes' : 'No',
      'UserID':
          userIdNumber != null
              ? userIdNumber.toString()
              : userId.substring(0, 8),
      'Description': generatedDescription,
    };

    return UserProfile(
      id: userId,
      name: getName(), // Use the helper method
      age: age,
      location: location.city,
      roomType: roomType ?? 'private',
      budget: budget ?? 'Flexible',
      bio: bio ?? generatedDescription,
      interests: interests,
      photoUrl: primaryPicture,
      preferences: additionalInfo,
    );
  }

  // Format last active time in a user-friendly way
  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${lastActive.day}/${lastActive.month}/${lastActive.year}';
    }
  }
}

class ProfilePictureModel {
  final String id;
  final String url;
  final bool isPrimary;

  ProfilePictureModel({
    required this.id,
    required this.url,
    required this.isPrimary,
  });

  factory ProfilePictureModel.fromJson(Map<String, dynamic> json) {
    return ProfilePictureModel(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      isPrimary: json['isPrimary'] == true || json['is_primary'] == true,
    );
  }
}

class LocationModel {
  final String city;
  final String? neighborhood;

  LocationModel({required this.city, this.neighborhood});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    String city = 'Unknown';

    // Handle different possible formats for the city
    if (json['city'] != null) {
      city = json['city'].toString();
    }

    return LocationModel(
      city: city,
      neighborhood: json['neighborhood']?.toString(),
    );
  }
}

class LifestyleModel {
  final String? schedule;
  final String? noiseLevel;
  final String? cookingFrequency;
  final String? smoking;
  final String? drinking;
  final String? pets;
  final String? cleaningHabits;
  final String? guestPolicy;

  LifestyleModel({
    this.schedule,
    this.noiseLevel,
    this.cookingFrequency,
    this.smoking,
    this.drinking,
    this.pets,
    this.cleaningHabits,
    this.guestPolicy,
  });

  factory LifestyleModel.fromJson(Map<String, dynamic> json) {
    return LifestyleModel(
      schedule: json['schedule']?.toString(),
      noiseLevel:
          json['noiseLevel']?.toString() ?? json['noise_level']?.toString(),
      cookingFrequency:
          json['cookingFrequency']?.toString() ??
          json['cooking_frequency']?.toString(),
      smoking: json['smoking']?.toString(),
      drinking: json['drinking']?.toString(),
      pets: json['pets']?.toString(),
      cleaningHabits:
          json['cleaningHabits']?.toString() ??
          json['cleaning_habits']?.toString(),
      guestPolicy:
          json['guestPolicy']?.toString() ?? json['guest_policy']?.toString(),
    );
  }
}
