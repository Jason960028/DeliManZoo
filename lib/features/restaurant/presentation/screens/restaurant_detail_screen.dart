import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../../../core/widgets/glassmorphic_container.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final RestaurantEntity restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load detailed restaurant information
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This would need proper DI setup in a real app
      // ref.read(restaurantDetailProvider.notifier).loadRestaurantDetails(widget.restaurant.placeId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For now, using the basic restaurant data passed in
    // In a real app, this would use the detailed data from the provider
    final restaurant = widget.restaurant;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, restaurant),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildImageCarousel(context, restaurant),
              _buildBasicInfoSection(context, restaurant),
              _buildBusinessHoursSection(context, restaurant),
              _buildContactSection(context, restaurant),
              _buildMapSection(context, restaurant),
              _buildReviewsSection(context),
              const SizedBox(height: 100), // Space for FABs
            ]),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(context, restaurant),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildSliverAppBar(BuildContext context, RestaurantEntity restaurant) {
    return SliverAppBar(
      expandedHeight: 100.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          restaurant.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 3.0,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context, RestaurantEntity restaurant) {
    final photos = restaurant.photos ?? ['placeholder'];
    
    return Container(
      height: 250,
      margin: const EdgeInsets.all(16),
      child: GlassmorphicContainer(
        borderRadius: 20,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: photos[index] == 'placeholder'
                      ? Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.restaurant,
                            size: 80,
                            color: Colors.grey,
                          ),
                        )
                      : Image.network(
                          _buildPhotoUrl(photos[index]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.restaurant,
                                size: 80,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                );
              },
            ),
            if (photos.length > 1)
              Positioned(
                bottom: 16,
                right: 16,
                child: GlassmorphicContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  borderRadius: 15,
                  backgroundColorWithOpacity: Colors.black.withValues(alpha: 0.5),
                  child: Text(
                    '${_currentImageIndex + 1} / ${photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, RestaurantEntity restaurant) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (restaurant.priceLevel != null)
                  Text(
                    '\$' * restaurant.priceLevel!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    restaurant.formattedAddress ?? restaurant.address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (restaurant.types?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: restaurant.types!.take(3).map((type) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatRestaurantType(type),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHoursSection(BuildContext context, RestaurantEntity restaurant) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  l10n.businessHours,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (restaurant.openNow != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: restaurant.openNow! ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  restaurant.openNow! ? l10n.openNow : l10n.closedNow,
                  style: TextStyle(
                    color: restaurant.openNow! ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            if (restaurant.openingHours?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _buildOpeningHours(context, restaurant.openingHours!),
            ] else
              Text(l10n.noBusinessHoursInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningHours(BuildContext context, Map<String, dynamic> openingHours) {
    final l10n = AppLocalizations.of(context)!;
    
    if (openingHours['weekday_text'] != null) {
      final List<String> weekdayText = List<String>.from(openingHours['weekday_text']);
      return Column(
        children: weekdayText.map((dayInfo) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              dayInfo,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      );
    }
    return Text(l10n.cannotLoadBusinessHours);
  }

  Widget _buildContactSection(BuildContext context, RestaurantEntity restaurant) {
    final l10n = AppLocalizations.of(context)!;
    final hasPhone = restaurant.phoneNumber?.isNotEmpty == true;
    final hasWebsite = restaurant.website?.isNotEmpty == true;
    
    if (!hasPhone && !hasWebsite) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_phone, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  l10n.contact,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasPhone)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone, color: Colors.green),
                title: Text(restaurant.phoneNumber!),
                trailing: const Icon(Icons.call, color: Colors.green),
                onTap: () => _makePhoneCall(restaurant.phoneNumber!),
              ),
            if (hasWebsite)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.web, color: Colors.blue),
                title: Text(
                  l10n.website,
                  style: TextStyle(color: Colors.blue.shade700),
                ),
                trailing: const Icon(Icons.open_in_browser, color: Colors.blue),
                onTap: () => _launchWebsite(restaurant.website!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context, RestaurantEntity restaurant) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  l10n.location,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(restaurant.lat, restaurant.lng),
                    zoom: 16,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('restaurant'),
                      position: LatLng(restaurant.lat, restaurant.lng),
                      infoWindow: InfoWindow(title: restaurant.name),
                    ),
                  },
                  onMapCreated: (GoogleMapController controller) {
                  },
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  l10n.reviews,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // TODO: Implement Firebase reviews
            Text(l10n.loadingReviews),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context, RestaurantEntity restaurant) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'favorite',
          onPressed: () => _toggleFavorite(restaurant),
          backgroundColor: Colors.red.shade400,
          child: const Icon(Icons.favorite_border),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'review',
          onPressed: () => _writeReview(restaurant),
          backgroundColor: Colors.blue.shade400,
          child: const Icon(Icons.rate_review),
        ),
      ],
    );
  }

  String _buildPhotoUrl(String photoReference) {
    // This would need your actual API key
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=YOUR_API_KEY';
  }

  String _formatRestaurantType(String type) {
    return type.replaceAll('_', ' ').split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cannotMakeCall)),
        );
      }
    }
  }

  Future<void> _launchWebsite(String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cannotOpenWebsite)),
        );
      }
    }
  }

  void _toggleFavorite(RestaurantEntity restaurant) {
    // TODO: Implement favorite functionality
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.addedToFavorites(restaurant.name))),
    );
  }

  void _writeReview(RestaurantEntity restaurant) {
    // TODO: Navigate to review writing screen
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.navigateToReview)),
    );
  }
}
