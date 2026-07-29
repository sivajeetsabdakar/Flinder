import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import 'flats_screen.dart';
import '../../widgets/flats/flat_filters.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter states
  String? _selectedCity;
  RangeValues _rentRange = const RangeValues(5000, 50000);
  int? _selectedRooms;

  // Reference to the FlatsScreen key
  final GlobalKey<FlatsScreenState> _flatsScreenKey =
      GlobalKey<FlatsScreenState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkerPurple,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: TabBar(
                controller: _tabController,
                indicator: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.primaryPurple,
                      width: 2.0,
                    ),
                  ),
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.event)),
                  Tab(icon: Icon(Icons.apartment)),
                ],
              ),
            ),
          ),

          // Search and filter bar
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.darkerPurple,
              border: Border(
                top: BorderSide(color: Colors.purple.shade800, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text(
                      'Find Flats',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: () {
                    if (_tabController.index == 1) {
                      _showFilterBottomSheet(context);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onPressed: () {
                    // Navigate to details or next screen
                  },
                ),
              ],
            ),
          ),

          // TabBarView content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildEventsTab(), FlatsScreen(key: _flatsScreenKey)],
            ),
          ),
        ],
      ),

      // Bottom action for logout
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () => _showLogoutDialog(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.darkerPurple.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout, size: 18, color: Colors.white70),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              Navigator.pop(context);

              // Apply filters to FlatsScreen
              if (_flatsScreenKey.currentState != null) {
                _flatsScreenKey.currentState!.applyExternalFilters(
                  _selectedCity,
                  _rentRange,
                  _selectedRooms,
                );
              }
            },
            onReset: () {
              setState(() {
                _selectedCity = null;
                _rentRange = const RangeValues(5000, 50000);
                _selectedRooms = null;
              });
              Navigator.pop(context);

              // Reset filters in FlatsScreen
              if (_flatsScreenKey.currentState != null) {
                _flatsScreenKey.currentState!.resetFilters();
              }
            },
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.darkGrey,
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => _handleLogout(context),
                child: Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.accentPink),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.of(context).pop(); // Close dialog

    try {
      await AuthService.logout();

      if (context.mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.initialize();
        AppRouter.navigateToLogin(context);
      }
    } catch (e) {
      print('Error during logout: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error during logout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEventsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore,
            size: 80,
            color: AppTheme.primaryPurple.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Coming Soon!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Discover exciting networking events to meet flatmates in person.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This feature is coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Notify Me', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
