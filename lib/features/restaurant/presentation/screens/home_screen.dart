import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui';

import '../../../../core/error/failure.dart';
import '../../../../core/widgets/glassmorphic_container.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../providers/restaurant_providers.dart';
import 'restaurant_detail_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final LatLng _initialPosition = const LatLng(37.5665, 126.9780);
  bool _isMapReady = false;
  final DraggableScrollableController _scrollController = DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  RestaurantEntity? _selectedRestaurant;
  bool _showSearchThisAreaButton = false;
  bool _isSearchExpanded = false;

  static const double _sheetMinSize = 0.15;
  static const double _sheetInitialSize = 0.15;
  static const double _sheetSnapMidSize = 0.5;
  static const double _sheetMaxSize = 0.8;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchExpanded = _searchFocusNode.hasFocus;
      });
    });
  }

  void _fetchRestaurantsForCurrentMapArea() {
    if (_mapController != null && _isMapReady) {
      _mapController!.getVisibleRegion().then((bounds) {
        final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
        final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;

        ref.read(restaurantListProvider.notifier).fetchRestaurantsForLocation(centerLat, centerLng);
        if (mounted) {
          setState(() {
            _showSearchThisAreaButton = false;
          });
        }
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    final currentRestaurantState = ref.read(restaurantListProvider);
    currentRestaurantState.whenData((restaurants) {
      if (restaurants.isNotEmpty) {
        final firstRestaurant = restaurants.first;
        _moveCameraToPosition(LatLng(firstRestaurant.lat, firstRestaurant.lng));
      } else {
        _tryMoveToCurrentLocation();
      }
    });
  }

  Future<void> _tryMoveToCurrentLocation() async {
    try {
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      _moveCameraToPosition(LatLng(position.latitude, position.longitude));
    } catch (e) {
      _moveCameraToPosition(_initialPosition);
    }
  }

  void _moveCameraToPosition(LatLng position, {double zoom = 15.0}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ),
    );
  }

  void _updateMarkers(List<RestaurantEntity> restaurants) {
    final Set<Marker> newMarkers = restaurants.map((restaurant) {
      final isSelected = _selectedRestaurant?.placeId == restaurant.placeId;
      return Marker(
        markerId: MarkerId(restaurant.placeId),
        position: LatLng(restaurant.lat, restaurant.lng),
        infoWindow: InfoWindow(
          title: restaurant.name,
          snippet: restaurant.address,
          onTap: () {
            setState(() {
              _selectedRestaurant = restaurant;
            });
            _moveCameraToPosition(LatLng(restaurant.lat, restaurant.lng), zoom: 16);
            _scrollController.animateTo(
              _sheetSnapMidSize,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        icon: isSelected
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        zIndexInt: isSelected ? 1 : 0,
        onTap: () {
          setState(() {
            _selectedRestaurant = restaurant;
          });
          _moveCameraToPosition(LatLng(restaurant.lat, restaurant.lng), zoom: 16);
          _scrollController.animateTo(
            _sheetSnapMidSize,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      );
    }).toSet();

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _handleSearch(String query) {
    if (query.isNotEmpty) {
      ref.read(restaurantListProvider.notifier).searchRestaurants(query);
      _searchFocusNode.unfocus();
    }
  }

  Widget _buildFloatingSearchBar(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: GlassmorphicContainer(
          borderRadius: _isSearchExpanded ? 16.0 : 28.0,
          backgroundColorWithOpacity: colorScheme.surface.withOpacity(0.95),
          border: Border.all(
            color: _isSearchExpanded
                ? colorScheme.primary.withOpacity(0.3)
                : colorScheme.outline.withOpacity(0.1),
            width: _isSearchExpanded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Menu Button (optional - you can remove this if not needed)
                    IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        // Open drawer or menu
                      },
                    ),

                    // Search Field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search Here',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onSubmitted: _handleSearch,
                        textInputAction: TextInputAction.search,
                      ),
                    ),

                    // Clear button (shows when text is entered)
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),

                    // Divider
                    Container(
                      height: 32,
                      width: 1,
                      color: colorScheme.outline.withOpacity(0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),

                    // Profile Avatar
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed('/profile');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: currentUser?.photoURL != null
                              ? NetworkImage(currentUser!.photoURL!)
                              : null,
                          child: currentUser?.photoURL == null
                              ? Icon(
                            Icons.person,
                            size: 20,
                            color: colorScheme.onPrimaryContainer,
                          )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search suggestions or recent searches (shown when expanded)
              if (_isSearchExpanded)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      // Recent searches or suggestions
                      _buildSearchSuggestion(
                        icon: Icons.history,
                        text: '카페',
                        onTap: () {
                          _searchController.text = '카페';
                          _handleSearch('카페');
                        },
                      ),
                      _buildSearchSuggestion(
                        icon: Icons.history,
                        text: '한식',
                        onTap: () {
                          _searchController.text = '한식';
                          _handleSearch('한식');
                        },
                      ),
                      _buildSearchSuggestion(
                        icon: Icons.location_on,
                        text: '주변 맛집',
                        onTap: () {
                          ref.read(restaurantListProvider.notifier).fetchRestaurantsForCurrentLocation();
                          _searchFocusNode.unfocus();
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestion({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
      dense: true,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<RestaurantEntity>>>(restaurantListProvider, (previous, next) {
      next.whenData((restaurants) {
        _updateMarkers(restaurants);
        if (_selectedRestaurant != null && !restaurants.any((r) => r.placeId == _selectedRestaurant!.placeId)) {
          if (mounted) {
            setState(() {
              _selectedRestaurant = null;
            });
          }
        }
      });
    });

    final restaurantsAsyncValue = ref.watch(restaurantListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final darkContentColor = colorScheme.onSurface;
    final darkMutedContentColor = colorScheme.onSurfaceVariant;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.6),
                  colorScheme.secondaryContainer.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Google Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
            onMapCreated: _onMapCreated,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            padding: EdgeInsets.only(
              top: 100, // Space for search bar
              bottom: MediaQuery.of(context).size.height * _sheetMinSize,
            ),
            onCameraIdle: () {
              if (_mapController != null && _isMapReady && !_isSearchExpanded) {
                _mapController!.getVisibleRegion().then((bounds) {
                  if (mounted) {
                    setState(() {
                      _showSearchThisAreaButton = true;
                    });
                  }
                });
              }
            },
            onTap: (_) {
              // Unfocus search when map is tapped
              _searchFocusNode.unfocus();
              if (mounted) {
                setState(() {
                  _selectedRestaurant = null;
                });
              }
              _scrollController.animateTo(
                _sheetInitialSize,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              _updateMarkers(restaurantsAsyncValue.asData?.value ?? []);
            },
          ),

          // "Search This Area" button
          if (_showSearchThisAreaButton && !_isSearchExpanded)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.search, color: colorScheme.onPrimary),
                  label: Text(
                    'Search This Area',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    _fetchRestaurantsForCurrentMapArea();
                  },
                ),
              ),
            ),

          // Bottom sheet with restaurant list
          DraggableScrollableSheet(
            controller: _scrollController,
            initialChildSize: _sheetInitialSize,
            minChildSize: _sheetMinSize,
            maxChildSize: _sheetMaxSize,
            snap: true,
            snapSizes: const [_sheetMinSize, _sheetSnapMidSize, _sheetMaxSize],
            builder: (BuildContext context, ScrollController sheetScrollController) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: GlassmorphicContainer(
                    borderRadius: 16.0,
                    blurSigmaX: 0.0,
                    blurSigmaY: 0.0,
                    backgroundColorWithOpacity: colorScheme.surface.withOpacity(0.15),
                    border: Border.all(color: colorScheme.onSurface.withOpacity(0.10)),
                    child: restaurantsAsyncValue.when(
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                error is Failure ? error.message : "목록 로딩 중 오류가 발생했습니다.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: Icon(Icons.refresh, color: colorScheme.onErrorContainer),
                                label: Text(
                                  '다시 시도',
                                  style: TextStyle(color: colorScheme.onErrorContainer),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.errorContainer.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onPressed: () => ref
                                    .read(restaurantListProvider.notifier)
                                    .fetchRestaurantsForCurrentLocation(),
                              )
                            ],
                          ),
                        ),
                      ),
                      data: (restaurants) {
                        if (restaurants.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                '주변에 표시할 음식점이 없습니다.',
                                style: TextStyle(color: darkContentColor, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.symmetric(vertical: 10.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                controller: sheetScrollController,
                                itemCount: restaurants.length,
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                                itemBuilder: (context, index) {
                                  final restaurant = restaurants[index];
                                  final bool isSelected = _selectedRestaurant?.placeId == restaurant.placeId;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                                    child: GlassmorphicContainer(
                                      height: 90,
                                      borderRadius: 12.0,
                                      backgroundColorWithOpacity: isSelected
                                          ? colorScheme.primaryContainer.withOpacity(0.5)
                                          : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : Colors.white.withOpacity(0.2),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(12.0),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    RestaurantDetailScreen(restaurant: restaurant),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(12.0),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12.0, vertical: 8.0),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.restaurant,
                                                  color: isSelected
                                                      ? colorScheme.onPrimaryContainer
                                                      : darkContentColor,
                                                  size: 28,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        restaurant.name,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          color: isSelected
                                                              ? colorScheme.onPrimaryContainer
                                                              : darkContentColor,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (restaurant.address.isNotEmpty)
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 2.0),
                                                          child: Text(
                                                            restaurant.address,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: isSelected
                                                                  ? colorScheme.onPrimaryContainer
                                                                  .withOpacity(0.8)
                                                                  : darkMutedContentColor,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (restaurant.rating > 0)
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        color: isSelected
                                                            ? colorScheme.onPrimaryContainer
                                                            .withOpacity(0.9)
                                                            : Colors.amber.shade700,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        restaurant.rating.toStringAsFixed(1),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: isSelected
                                                              ? colorScheme.onPrimaryContainer
                                                              .withOpacity(0.8)
                                                              : darkContentColor,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                else
                                                  Text(
                                                    '평점 없음',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isSelected
                                                          ? colorScheme.onPrimaryContainer
                                                          .withOpacity(0.6)
                                                          : darkMutedContentColor,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating Search Bar (Google Maps style)
          _buildFloatingSearchBar(context),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}