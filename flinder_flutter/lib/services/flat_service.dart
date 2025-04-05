import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/flat_model.dart';
import '../constants/api_constants.dart';

class FlatService {
  static const String baseUrl = ApiConstants.baseUrl;

  // Get all flats with optional filters
  static Future<Map<String, dynamic>> getFlats({
    String? city,
    int? minRent,
    int? maxRent,
    int? rooms,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (city != null) queryParams['city'] = city;
      if (minRent != null) queryParams['minRent'] = minRent.toString();
      if (maxRent != null) queryParams['maxRent'] = maxRent.toString();
      if (rooms != null) queryParams['rooms'] = rooms.toString();
      queryParams['limit'] = limit.toString();
      queryParams['offset'] = offset.toString();

      final uri = Uri.parse(
        '$baseUrl/api/flats',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Parse flats from response
        final List<FlatModel> flats =
            (data['flats'] as List)
                .map((flatJson) => FlatModel.fromJson(flatJson))
                .toList();

        // Return both flats and pagination info
        return {'flats': flats, 'pagination': data['pagination']};
      } else {
        throw Exception('Failed to load flats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching flats: $e');

      // Return dummy data for testing
      return _getDummyFlats();
    }
  }

  // Get a specific flat by ID
  static Future<FlatModel> getFlatById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/flats/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return FlatModel.fromJson(data['flat']);
      } else {
        throw Exception('Failed to load flat details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching flat details: $e');

      // Return dummy data for testing
      final dummyData = _getDummyFlats();
      final dummyFlats = dummyData['flats'] as List<FlatModel>;

      // Return the first flat or create a new one if the list is empty
      return dummyFlats.firstWhere(
        (flat) => flat.id == id,
        orElse: () => dummyFlats.first,
      );
    }
  }

  // Generate dummy flats data for testing
  static Map<String, dynamic> _getDummyFlats() {
    final flats = [
      FlatModel(
        id: '1',
        title: 'Modern 2BHK in City Center',
        address: '123 Main Street, Sector 15',
        city: 'Gandhinagar',
        rent: 12000,
        numRooms: 2,
        amenities: ['WiFi', 'AC', 'Fully Furnished', 'Security'],
        description:
            'A beautiful modern flat in the heart of the city with all amenities nearby.',
        imageUrl:
            'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
      ),
      FlatModel(
        id: '2',
        title: 'Spacious 3BHK Family Apartment',
        address: '45 Park Avenue, Sector 8',
        city: 'Gandhinagar',
        rent: 18000,
        numRooms: 3,
        amenities: ['WiFi', 'AC', 'Parking', 'Swimming Pool', 'Gym'],
        description:
            'Perfect for families, this spacious flat offers comfort and convenience with excellent amenities.',
        imageUrl:
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
      ),
      FlatModel(
        id: '3',
        title: 'Cozy 1BHK Studio Apartment',
        address: '78 College Road, Navrangpura',
        city: 'Ahmedabad',
        rent: 8000,
        numRooms: 1,
        amenities: ['WiFi', 'AC', 'Balcony'],
        description:
            'A cozy studio apartment perfect for students or young professionals, located near major colleges.',
        imageUrl:
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
      ),
      FlatModel(
        id: '4',
        title: 'Luxury 4BHK Penthouse',
        address: '12 Riverside Drive, Vastrapur',
        city: 'Ahmedabad',
        rent: 35000,
        numRooms: 4,
        amenities: [
          'WiFi',
          'AC',
          'Terrace Garden',
          'Private Elevator',
          'Premium Furnishings',
        ],
        description:
            'Experience luxury living in this premium penthouse with stunning city views and exclusive amenities.',
        imageUrl:
            'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
      ),
      FlatModel(
        id: '5',
        title: '2BHK Flat near Tech Park',
        address: '34 Innovation Street, InfoCity',
        city: 'Gandhinagar',
        rent: 14500,
        numRooms: 2,
        amenities: ['WiFi', 'AC', 'Furnished', 'Power Backup'],
        description:
            'Conveniently located near major tech companies, this flat is ideal for IT professionals.',
        imageUrl:
            'https://images.unsplash.com/photo-1493809842364-78817add7ffb?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
      ),
    ];

    return {
      'flats': flats,
      'pagination': {'limit': 10, 'offset': 0, 'total': flats.length},
    };
  }
}
