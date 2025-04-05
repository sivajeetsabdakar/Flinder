class FlatModel {
  final String id;
  final String title;
  final String address;
  final String city;
  final int rent;
  final int numRooms;
  final List<String> amenities;
  final String description;
  final String? imageUrl;
  final DateTime? createdAt;

  FlatModel({
    required this.id,
    required this.title,
    required this.address,
    required this.city,
    required this.rent,
    required this.numRooms,
    required this.amenities,
    required this.description,
    this.imageUrl,
    this.createdAt,
  });

  factory FlatModel.fromJson(Map<String, dynamic> json) {
    return FlatModel(
      id: json['id'],
      title: json['title'],
      address: json['address'],
      city: json['city'],
      rent: json['rent'],
      numRooms: json['num_rooms'],
      amenities: List<String>.from(json['amenities'] ?? []),
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'city': city,
      'rent': rent,
      'num_rooms': numRooms,
      'amenities': amenities,
      'description': description,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
