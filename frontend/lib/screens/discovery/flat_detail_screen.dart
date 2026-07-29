import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/flat_model.dart';
import '../../models/chat_thread.dart';
import '../../providers/chat_context.dart';
import '../../services/flat_service.dart';
import '../../services/flat_application_service.dart';
import '../../theme/app_theme.dart';

class FlatDetailScreen extends StatefulWidget {
  final String flatId;

  const FlatDetailScreen({Key? key, required this.flatId}) : super(key: key);

  @override
  _FlatDetailScreenState createState() => _FlatDetailScreenState();
}

class _FlatDetailScreenState extends State<FlatDetailScreen> {
  bool _isLoading = true;
  bool _isApplying = false;
  FlatModel? _flat;
  String? _error;
  String? _selectedGroupId;
  List<ChatThread> _groupChats = [];

  @override
  void initState() {
    super.initState();
    _loadFlatDetails();
    _loadGroupChats();
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

  Future<void> _loadGroupChats() async {
    try {
      final chatContext = Provider.of<ChatContext>(context, listen: false);
      await chatContext.loadChatThreads();

      if (mounted) {
        setState(() {
          // Filter only group chats
          _groupChats =
              chatContext.threads.where((thread) => thread.isGroup).toList();

          // Select the first group chat by default if available
          if (_groupChats.isNotEmpty && _selectedGroupId == null) {
            _selectedGroupId = _groupChats.first.id;
          }
        });
      }
    } catch (e) {
      print('Error loading group chats: $e');
    }
  }

  Future<void> _applyForFlat() async {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a group to apply with'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isApplying = true;
    });

    try {
      final application = await FlatApplicationService.applyForFlat(
        flatId: widget.flatId,
        groupChatId: _selectedGroupId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying for flat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
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
    return Stack(
      children: [
        CustomScrollView(
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

                  // Add the group chat selection and apply button
                  _buildApplicationSection(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApplicationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apply with your group',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          if (_groupChats.isEmpty)
            const Text(
              'You don\'t have any group chats yet. Create a group chat to apply for this flat.',
              style: TextStyle(color: Colors.grey),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a group to apply with:',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _buildGroupSelector(),
                const SizedBox(height: 16),
                _buildApplyButton(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGroupId,
          isExpanded: true,
          dropdownColor: Colors.grey[800],
          style: const TextStyle(color: Colors.white),
          hint: const Text(
            'Select a group',
            style: TextStyle(color: Colors.grey),
          ),
          items:
              _groupChats.map((group) {
                return DropdownMenuItem<String>(
                  value: group.id,
                  child: Text(
                    group.name ?? 'Unnamed Group',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGroupId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isApplying ? null : _applyForFlat,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            _isApplying
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Apply Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
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
      expandedHeight: 60,
      pinned: true,
      backgroundColor: Colors.black,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}
