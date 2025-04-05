import 'package:flutter/material.dart';
import '../../models/flat_model.dart';
import '../../services/flat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_with_logout.dart';
import '../../widgets/flats/flat_item.dart';
import '../../widgets/flats/flat_filters.dart';
import '../../routes/app_router.dart';

class FlatsScreen extends StatefulWidget {
  const FlatsScreen({Key? key}) : super(key: key);

  @override
  FlatsScreenState createState() => FlatsScreenState();
}

class FlatsScreenState extends State<FlatsScreen> {
  bool _isLoading = false;
  List<FlatModel> _flats = [];
  String? _error;

  // Pagination
  int _limit = 10;
  int _offset = 0;
  int _total = 0;
  bool _hasMore = true;

  // Filters
  String? _selectedCity;
  RangeValues _rentRange = const RangeValues(5000, 50000);
  int? _selectedRooms;

  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFlats();

    // Add scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadMoreFlats();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFlats() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _offset = 0;
    });

    try {
      final result = await FlatService.getFlats(
        city: _selectedCity,
        minRent: _rentRange.start.round(),
        maxRent: _rentRange.end.round(),
        rooms: _selectedRooms,
        limit: _limit,
        offset: _offset,
      );

      if (mounted) {
        setState(() {
          _flats = result['flats'] as List<FlatModel>;
          _total = result['pagination']['total'] as int;
          _hasMore = _flats.length < _total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load flats: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreFlats() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _offset += _limit;
    });

    try {
      final result = await FlatService.getFlats(
        city: _selectedCity,
        minRent: _rentRange.start.round(),
        maxRent: _rentRange.end.round(),
        rooms: _selectedRooms,
        limit: _limit,
        offset: _offset,
      );

      final newFlats = result['flats'] as List<FlatModel>;

      if (mounted) {
        setState(() {
          _flats.addAll(newFlats);
          _hasMore = _flats.length < _total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load more flats: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Method to accept filters from external sources like DiscoverScreen
  void applyExternalFilters(String? city, RangeValues? rentRange, int? rooms) {
    setState(() {
      _selectedCity = city;
      if (rentRange != null) _rentRange = rentRange;
      _selectedRooms = rooms;
    });
    _loadFlats();
  }

  void resetFilters() {
    setState(() {
      _selectedCity = null;
      _rentRange = const RangeValues(5000, 50000);
      _selectedRooms = null;
    });
    _loadFlats();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: FlatFilters(
            selectedCity: _selectedCity,
            rentRange: _rentRange,
            selectedRooms: _selectedRooms,
            onCityChanged: (city) => _selectedCity = city,
            onRentRangeChanged: (range) => _rentRange = range!,
            onRoomsChanged: (rooms) => _selectedRooms = rooms,
            onApply: () {
              Navigator.pop(bottomSheetContext);
              _loadFlats();
            },
            onReset: () {
              resetFilters();
              Navigator.pop(bottomSheetContext);
            },
          ),
        );
      },
    );
  }

  void _navigateToFlatDetail(FlatModel flat) {
    AppRouter.navigateToFlatDetail(context, flat.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading && _flats.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
        ),
      );
    }

    if (_error != null && _flats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFlats,
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
      );
    }

    if (_flats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apartment, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              'No Flats Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Applied filters chips
        if (_selectedCity != null || _selectedRooms != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedCity != null)
                  _buildFilterChip(_selectedCity!, () {
                    setState(() {
                      _selectedCity = null;
                    });
                    _loadFlats();
                  }),
                if (_selectedRooms != null)
                  _buildFilterChip('${_selectedRooms!} BHK', () {
                    setState(() {
                      _selectedRooms = null;
                    });
                    _loadFlats();
                  }),
                _buildFilterChip(
                  '₹${_rentRange.start.round()} - ₹${_rentRange.end.round()}',
                  () {
                    setState(() {
                      _rentRange = const RangeValues(5000, 50000);
                    });
                    _loadFlats();
                  },
                ),
              ],
            ),
          ),

        // Results count
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 4,
          ),
          child: Text(
            'Showing ${_flats.length} of $_total results',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ),

        // Flats list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadFlats,
            color: AppTheme.primaryPurple,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: _flats.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _flats.length) {
                  return FlatItem(
                    flat: _flats[index],
                    onTap: () => _navigateToFlatDetail(_flats[index]),
                  );
                } else {
                  // Loading indicator at the bottom for pagination
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      backgroundColor: AppTheme.primaryPurple.withOpacity(0.2),
      label: Text(
        label,
        style: TextStyle(color: AppTheme.primaryPurple, fontSize: 12),
      ),
      deleteIcon: const Icon(
        Icons.close,
        size: 16,
        color: AppTheme.primaryPurple,
      ),
      onDeleted: onRemove,
    );
  }
}
