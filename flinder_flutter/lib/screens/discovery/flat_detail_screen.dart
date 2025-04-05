import 'package:flutter/material.dart';
import '../../models/flat_model.dart';
import '../../services/flat_service.dart';
import '../../theme/app_theme.dart';

class FlatDetailScreen extends StatefulWidget {
  final String flatId;

  const FlatDetailScreen({Key? key, required this.flatId}) : super(key: key);

  @override
  _FlatDetailScreenState createState() => _FlatDetailScreenState();
}

class _FlatDetailScreenState extends State<FlatDetailScreen> {
  bool _isLoading = true;
  FlatModel? _flat;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFlatDetails();
  }

  Future<void> _loadFlatDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final flat = await FlatService.getFlatById(widget.flatId);
      if (mounted) {
        setState(() {
          _flat = flat;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load flat details: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryPurple,
                  ),
                ),
              )
              : _error != null
              ? _buildErrorScreen()
              : _flat != null
              ? _buildFlatDetails()
              : _buildEmptyState(),
    );
  }

  Widget _buildErrorScreen() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(title: 'Error'),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[300]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadFlatDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(title: 'Not Found'),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_outlined, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'Flat not found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The requested flat could not be found',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlatDetails() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(title: _flat!.title),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero image
              AspectRatio(
                aspectRatio: 16 / 9,
                child:
                    _flat!.imageUrl != null
                        ? Image.network(
                          _flat!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(
                                  Icons.apartment,
                                  size: 50,
                                  color: Colors.white70,
                                ),
                              ),
                            );
                          },
                        )
                        : Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(
                              Icons.apartment,
                              size: 50,
                              color: Colors.white70,
                            ),
                          ),
                        ),
              ),

              // Price and details card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _flat!.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹${_flat!.rent.toString()}/mo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Address
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_flat!.address}, ${_flat!.city}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Flat details
                    Row(
                      children: [
                        _buildDetailItem(
                          Icons.bedroom_parent_outlined,
                          '${_flat!.numRooms} BHK',
                        ),
                        const Spacer(),
                        _buildDetailItem(Icons.location_city, _flat!.city),
                      ],
                    ),
                  ],
                ),
              ),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _flat!.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[300],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amenities
              if (_flat!.amenities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amenities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children:
                            _flat!.amenities.map((amenity) {
                              return _buildAmenityItem(amenity);
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Contact button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contact feature coming soon!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Contact Owner',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),

              // Bottom padding
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryPurple),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 16, color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildAmenityItem(String amenity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: AppTheme.primaryPurple),
          const SizedBox(width: 8),
          Text(amenity, style: TextStyle(color: Colors.grey[300])),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar({required String title}) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Save feature coming soon!')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share feature coming soon!')),
            );
          },
        ),
      ],
    );
  }
}
