import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FlatFilters extends StatefulWidget {
  final String? selectedCity;
  final RangeValues? rentRange;
  final int? selectedRooms;
  final Function(String?) onCityChanged;
  final Function(RangeValues?) onRentRangeChanged;
  final Function(int?) onRoomsChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;

  const FlatFilters({
    Key? key,
    this.selectedCity,
    this.rentRange,
    this.selectedRooms,
    required this.onCityChanged,
    required this.onRentRangeChanged,
    required this.onRoomsChanged,
    required this.onApply,
    required this.onReset,
  }) : super(key: key);

  @override
  State<FlatFilters> createState() => _FlatFiltersState();
}

class _FlatFiltersState extends State<FlatFilters> {
  late String? _selectedCity;
  late RangeValues? _rentRange;
  late int? _selectedRooms;

  // Define some constants
  static const double minRent = 5000;
  static const double maxRent = 50000;
  static const List<String> cities = [
    'All Cities',
    'Gandhinagar',
    'Ahmedabad',
    'Surat',
    'Mumbai',
    'Delhi',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.selectedCity;
    _rentRange = widget.rentRange ?? const RangeValues(minRent, maxRent);
    _selectedRooms = widget.selectedRooms;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Flats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // City Filter
            const Text(
              'City',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  cities.map((city) {
                    final isSelected =
                        _selectedCity == city ||
                        (city == 'All Cities' && _selectedCity == null);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCity = city == 'All Cities' ? null : city;
                        });
                      },
                      child: Chip(
                        backgroundColor:
                            isSelected
                                ? AppTheme.primaryPurple
                                : Colors.grey[800],
                        label: Text(
                          city,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            // Rent Range Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rent Range',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${_rentRange!.start.round()} - ₹${_rentRange!.end.round()}',
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: _rentRange!,
              min: minRent,
              max: maxRent,
              divisions: 45,
              activeColor: AppTheme.primaryPurple,
              inactiveColor: Colors.grey[800],
              labels: RangeLabels(
                '₹${_rentRange!.start.round()}',
                '₹${_rentRange!.end.round()}',
              ),
              onChanged: (values) {
                setState(() {
                  _rentRange = values;
                });
              },
            ),
            const SizedBox(height: 16),

            // Number of Rooms
            const Text(
              'Number of Rooms',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  [0, 1, 2, 3, 4].map((rooms) {
                    final isSelected = _selectedRooms == rooms;
                    final label = rooms == 0 ? 'Any' : '$rooms BHK';

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRooms = rooms == 0 ? null : rooms;
                        });
                      },
                      child: Chip(
                        backgroundColor:
                            isSelected
                                ? AppTheme.primaryPurple
                                : Colors.grey[800],
                        label: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onReset,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryPurple),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(color: AppTheme.primaryPurple),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onCityChanged(_selectedCity);
                      widget.onRentRangeChanged(_rentRange);
                      widget.onRoomsChanged(_selectedRooms);
                      widget.onApply();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
            // Add extra space at the bottom for iPhone X and above
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
