import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String name;
  final int age;
  final String location;
  final String roomType;
  final String budget;
  final String? bio;
  final List<String>? interests;
  final Map<String, dynamic>? preferences;
  final String? photoUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.roomType,
    required this.budget,
    this.bio,
    this.interests,
    this.preferences,
    this.photoUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      age: json['age'] is int ? json['age'] : int.parse(json['age'].toString()),
      location:
          json['location'] is Map ? json['location']['city'] : json['location'],
      roomType: _getRoomTypeFromJson(json),
      budget: _getBudgetFromJson(json),
      bio: json['bio'],
      interests:
          json['interests'] != null
              ? List<String>.from(json['interests'])
              : null,
      preferences: json['preferences'],
      photoUrl: json['photoUrl'],
    );
  }

  static String _getRoomTypeFromJson(Map<String, dynamic> json) {
    if (json['preferences'] != null &&
        json['preferences']['critical'] != null &&
        json['preferences']['critical']['roomType'] != null) {
      return _formatRoomType(json['preferences']['critical']['roomType']);
    }
    return json['roomType'] ?? 'Any';
  }

  static String _getBudgetFromJson(Map<String, dynamic> json) {
    if (json['preferences'] != null &&
        json['preferences']['critical'] != null &&
        json['preferences']['critical']['budget'] != null) {
      final budget = json['preferences']['critical']['budget'];
      final min = budget['min'];
      final max = budget['max'];
      return '\$${min.toString()}-\$${max.toString()}';
    }
    return json['budget'] ?? 'Flexible';
  }

  static String _formatRoomType(String roomType) {
    switch (roomType.toLowerCase()) {
      case 'private':
        return 'Private Room';
      case 'shared':
        return 'Shared Room';
      case 'studio':
        return 'Studio';
      case 'any':
      default:
        return 'Any Room';
    }
  }

  static List<UserProfile> getDummyProfiles() {
    return [
      UserProfile(
        id: '1',
        name: 'Emma Watson',
        age: 28,
        location: 'London',
        roomType: 'Private',
        budget: 'Flexible',
        bio:
            'I\'m looking for a quiet and tidy flatmate. I work as a software engineer and enjoy reading in my free time. I usually wake up early and prefer a calm environment in the evening.',
        interests: ['Reading', 'Hiking', 'Cooking', 'Photography'],
        preferences: {
          'Schedule': 'Early bird (6AM-10PM)',
          'Noise': 'Prefer quiet environment',
          'Cooking': 'Cook often, happy to share meals',
          'Cleaning': 'Very tidy, clean weekly',
        },
        photoUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
      ),
      UserProfile(
        id: '2',
        name: 'Michael Johnson',
        age: 30,
        location: 'New York',
        roomType: 'Shared',
        budget: 'Flexible',
        bio:
            'Graphic designer looking for a creative space to share. I\'m friendly, respectful, and enjoy good conversations. I work from home most days and enjoy having friends over occasionally.',
        interests: ['Art', 'Movies', 'Travel', 'Music'],
        preferences: {
          'Schedule': 'Night owl (11AM-2AM)',
          'Noise': 'Moderate, enjoy music',
          'Guests': 'Occasionally have friends over',
          'Pets': 'Love animals, have none currently',
        },
        photoUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
      ),
      UserProfile(
        id: '3',
        name: 'Sophia Chen',
        age: 26,
        location: 'San Francisco',
        roomType: 'Private',
        budget: 'Flexible',
        bio:
            'Medical student looking for a quiet place. I\'m organized, clean, and respectful of shared spaces. I spend most of my time studying or at the hospital.',
        interests: ['Fitness', 'Cooking', 'Reading', 'Yoga'],
        preferences: {
          'Schedule': 'Early bird (5AM-10PM)',
          'Noise': 'Quiet environment for studying',
          'Cleaning': 'Very tidy, clean regularly',
          'Diet': 'Vegetarian, but don\'t mind others cooking meat',
        },
        photoUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
      ),
      UserProfile(
        id: '4',
        name: 'David Kim',
        age: 32,
        location: 'Seattle',
        roomType: 'Private',
        budget: 'Flexible',
        bio:
            'Musician and part-time barista. I\'m looking for an easy-going flatmate who doesn\'t mind some occasional music practice. I\'m tidy and respectful of shared spaces.',
        interests: ['Music', 'Coffee', 'Concerts', 'Cooking'],
        preferences: {
          'Schedule': 'Flexible hours',
          'Noise': 'Occasionally practice music at home',
          'Cleaning': 'Tidy, clean every few days',
          'Smoking': 'Non-smoker, prefer smoke-free home',
        },
        photoUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
      ),
      UserProfile(
        id: '5',
        name: 'Sarah Martinez',
        age: 29,
        location: 'Paris',
        roomType: 'Private',
        budget: 'Flexible',
        bio:
            'Marketing professional who loves to travel. Looking for a flatmate who is independent but also up for occasional movie nights and dinners together.',
        interests: ['Travel', 'Wine Tasting', 'Movies', 'Photography'],
        preferences: {
          'Schedule': 'Regular 9-5 worker',
          'Guests': 'Occasionally have friends over',
          'Cleaning': 'Tidy in common areas',
          'Alcohol': 'Social drinker, enjoy wine',
        },
        photoUrl:
            'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e',
      ),
      UserProfile(
        id: '6',
        name: 'James Wilson',
        age: 27,
        location: 'Berlin',
        roomType: 'Private',
        budget: 'Flexible',
        bio:
            'Software developer and avid gamer. I\'m friendly, laid-back, and neat. Looking for someone who is respectful of personal space and doesn\'t mind the occasional gaming session.',
        interests: ['Gaming', 'Coding', 'Board Games', 'Sci-Fi'],
        preferences: {
          'Schedule': 'Night owl (10AM-2AM)',
          'Noise': 'Moderate, use headphones when gaming',
          'Cleaning': 'Regular cleaning schedule',
          'Diet': 'Cook simple meals, often order in',
        },
        photoUrl: 'https://images.unsplash.com/photo-1542909168-82c3e7fdca5c',
      ),
      UserProfile(
        id: '7',
        name: 'Olivia Parker',
        age: 24,
        location: 'Tokyo',
        roomType: 'Private',
        budget: 'Flexible',
        bio:
            'Grad student in Environmental Science. I love spending time outdoors and am passionate about sustainability. Looking for an eco-conscious flatmate.',
        interests: ['Hiking', 'Gardening', 'Sustainability', 'Reading'],
        preferences: {
          'Schedule': 'Early bird (6AM-11PM)',
          'Diet': 'Primarily plant-based',
          'Cleaning': 'Eco-friendly products only',
          'Lifestyle': 'Environmentally conscious',
        },
        photoUrl:
            'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04',
      ),
    ];
  }
}
