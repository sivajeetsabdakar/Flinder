import 'package:flutter/material.dart';

class ProfileModel {
  final String userId;
  final String bio;
  final String? generatedDescription;
  final List<String> interests;
  final List<ProfilePicture> profilePictures;
  final Location location;
  final Budget budget;
  final String roomPreference;
  final String genderPreference;
  final String moveInDate;
  final String leaseDuration;
  final Lifestyle lifestyle;
  final List<String> languages;

  ProfileModel({
    required this.userId,
    required this.bio,
    this.generatedDescription,
    required this.interests,
    required this.profilePictures,
    required this.location,
    required this.budget,
    required this.roomPreference,
    required this.genderPreference,
    required this.moveInDate,
    required this.leaseDuration,
    required this.lifestyle,
    required this.languages,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['userId'],
      bio: json['bio'],
      generatedDescription: json['generatedDescription'],
      interests: List<String>.from(json['interests'] ?? []),
      profilePictures:
          (json['profilePictures'] as List?)
              ?.map((p) => ProfilePicture.fromJson(p))
              .toList() ??
          [],
      location: Location.fromJson(json['location'] ?? {}),
      budget: Budget.fromJson(json['budget'] ?? {}),
      roomPreference: json['roomPreference'] ?? 'any',
      genderPreference: json['genderPreference'] ?? 'any_gender',
      moveInDate: json['moveInDate'] ?? 'flexible',
      leaseDuration: json['leaseDuration'] ?? 'flexible',
      lifestyle: Lifestyle.fromJson(json['lifestyle'] ?? {}),
      languages: List<String>.from(json['languages'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'bio': bio,
      'generatedDescription': generatedDescription,
      'interests': interests,
      'profilePictures': profilePictures.map((p) => p.toJson()).toList(),
      'location': location.toJson(),
      'budget': budget.toJson(),
      'roomPreference': roomPreference,
      'genderPreference': genderPreference,
      'moveInDate': moveInDate,
      'leaseDuration': leaseDuration,
      'lifestyle': lifestyle.toJson(),
      'languages': languages,
    };
  }
}

class ProfilePicture {
  final String id;
  final String url;
  final bool isPrimary;
  final DateTime uploadedAt;

  ProfilePicture({
    required this.id,
    required this.url,
    required this.isPrimary,
    required this.uploadedAt,
  });

  factory ProfilePicture.fromJson(Map<String, dynamic> json) {
    return ProfilePicture(
      id: json['id'],
      url: json['url'],
      isPrimary: json['isPrimary'] ?? false,
      uploadedAt: DateTime.parse(json['uploadedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'isPrimary': isPrimary,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class Location {
  final String city;
  final String? neighborhood;
  final Coordinates? coordinates;

  Location({required this.city, this.neighborhood, this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      city: json['city'] ?? '',
      neighborhood: json['neighborhood'],
      coordinates:
          json['coordinates'] != null
              ? Coordinates.fromJson(json['coordinates'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'neighborhood': neighborhood,
      'coordinates': coordinates?.toJson(),
    };
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class Budget {
  final int min;
  final int max;
  final String currency;

  Budget({required this.min, required this.max, required this.currency});

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      min: json['min'] ?? 0,
      max: json['max'] ?? 0,
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {'min': min, 'max': max, 'currency': currency};
  }
}

class Lifestyle {
  final String schedule;
  final String noiseLevel;
  final String cookingFrequency;
  final String diet;
  final String smoking;
  final String drinking;
  final String pets;
  final String cleaningHabits;
  final String guestPolicy;

  Lifestyle({
    required this.schedule,
    required this.noiseLevel,
    required this.cookingFrequency,
    required this.diet,
    required this.smoking,
    required this.drinking,
    required this.pets,
    required this.cleaningHabits,
    required this.guestPolicy,
  });

  factory Lifestyle.fromJson(Map<String, dynamic> json) {
    return Lifestyle(
      schedule: json['schedule'] ?? 'flexible',
      noiseLevel: json['noiseLevel'] ?? 'moderate',
      cookingFrequency: json['cookingFrequency'] ?? 'sometimes',
      diet: json['diet'] ?? 'no_restrictions',
      smoking: json['smoking'] ?? 'no',
      drinking: json['drinking'] ?? 'occasionally',
      pets: json['pets'] ?? 'comfortable_with_pets',
      cleaningHabits: json['cleaningHabits'] ?? 'average',
      guestPolicy: json['guestPolicy'] ?? 'occasional_guests',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule': schedule,
      'noiseLevel': noiseLevel,
      'cookingFrequency': cookingFrequency,
      'diet': diet,
      'smoking': smoking,
      'drinking': drinking,
      'pets': pets,
      'cleaningHabits': cleaningHabits,
      'guestPolicy': guestPolicy,
    };
  }
}
