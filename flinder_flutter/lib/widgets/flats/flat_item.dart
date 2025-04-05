import 'package:flutter/material.dart';
import '../../models/flat_model.dart';
import '../../theme/app_theme.dart';

class FlatItem extends StatelessWidget {
  final FlatModel flat;
  final VoidCallback onTap;

  const FlatItem({Key? key, required this.flat, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flat image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child:
                    flat.imageUrl != null
                        ? Image.network(
                          flat.imageUrl!,
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
            ),

            // Flat details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rent
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          flat.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${flat.rent.toString()}/mo',
                          style: TextStyle(
                            color: AppTheme.primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${flat.address}, ${flat.city}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Room info and amenities
                  Row(
                    children: [
                      _buildInfoItem(
                        Icons.bedroom_parent,
                        '${flat.numRooms} BHK',
                      ),
                      const SizedBox(width: 16),
                      if (flat.amenities.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppTheme.primaryPurple,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  flat.amenities.take(2).join(' • ') +
                                      (flat.amenities.length > 2
                                          ? ' • ...'
                                          : ''),
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryPurple),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[300], fontSize: 14)),
      ],
    );
  }
}
