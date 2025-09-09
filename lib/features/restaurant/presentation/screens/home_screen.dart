import 'package:geocoding/geocoding.dart';
import 'dart:math';

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
  Key _mapKey = UniqueKey();

  static const double _sheetMinSize = 0.08;
  static const double _sheetInitialSize = 0.33; // 1/3 of screen
  static const double _sheetSnapMidSize = 0.6;
  static const double _sheetMaxSize = 0.9;

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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not get current location: ${e.toString()}'))
        );
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

  void _handleSearch(String query) async {
    if (query.isEmpty) return;

    _searchFocusNode.unfocus();

    try {
      List<Location> locations = await locationFromAddress(query, localeIdentifier: "ko_KR");
      if (locations.isNotEmpty) {
        final location = locations.first;
        _moveCameraToPosition(LatLng(location.latitude, location.longitude));
        setState(() {
          _mapKey = UniqueKey();
        });
      } else {
        // If no locations are found, search for restaurants as a fallback.
        ref.read(restaurantListProvider.notifier).searchRestaurants(query);
      }
    } catch (e) {
      // If geocoding fails (e.g., no network, or invalid query format for location),
      // assume it's a restaurant search query.
      if (e is NoResultFoundException) {
        // This is a specific case where the query is valid but finds no location.
        // We can choose to notify the user or just proceed to restaurant search.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('장소를 찾을 수 없어 음식점 검색을 시도합니다.')),
          );
        }
      }
      ref.read(restaurantListProvider.notifier).searchRestaurants(query);
    }
  }

  Widget _buildMyLocationButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8.0), // Add some padding around the button
      child: FloatingActionButton(
        onPressed: _tryMoveToCurrentLocation,
        backgroundColor: colorScheme.surface, // Use theme colors
        foregroundColor: colorScheme.primary, // Icon color
        elevation: 2.0,
        heroTag: null, // Add this if you might have multiple FABs on screen in the future
        mini: true,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildDraggableSheetWithSearch(
    BuildContext context,
    AsyncValue<List<RestaurantEntity>> restaurantsAsyncValue,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = ref.watch(currentUserProvider);

    return DraggableScrollableSheet(
      controller: _scrollController,
      initialChildSize: _sheetInitialSize,
      minChildSize: _sheetInitialSize, // Set min size to initial size
      maxChildSize: _sheetMaxSize,
      snap: true,
      snapSizes: const [_sheetInitialSize, _sheetSnapMidSize, _sheetMaxSize],
      builder: (BuildContext context, ScrollController sheetScrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: GlassmorphicContainer(
              borderRadius: 16.0,
              blurSigmaX: 0.0,
              blurSigmaY: 0.0,
              backgroundColorWithOpacity: colorScheme.surface.withValues(alpha: 0.15),
              border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.10)),
              child: Column(
                children: [
                  // Search Bar UI
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: GlassmorphicContainer(
                      borderRadius: 28.0,
                      backgroundColorWithOpacity: colorScheme.surface.withValues(alpha: 0.95),
                      border: Border.all(
                        color: _isSearchExpanded
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : colorScheme.outline.withValues(alpha: 0.1),
                        width: _isSearchExpanded ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.menu,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () {},
                                  ),
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
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                          fontSize: 16,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      onSubmitted: _handleSearch,
                                      textInputAction: TextInputAction.search,
                                    ),
                                  ),
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
                                  Container(
                                    height: 32,
                                    width: 1,
                                    color: colorScheme.outline.withValues(alpha: 0.2),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
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
                            Flexible(
                              child: _isSearchExpanded
                                  ? Container(
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      child: ListView(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.only(bottom: 8),
                                        children: [
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
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Restaurant List
                  Expanded(
                    child: Column(
                      children: [
                        // Enhanced sheet handle
                        Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: restaurantsAsyncValue.when(
                            loading: () => Center(
                              child: CircularProgressIndicator(
                                color: Colors.white.withValues(alpha: 0.7),
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
                                        color: Colors.white.withValues(alpha: 0.9),
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
                                        backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.8),
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
                                      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }
                              return ListView.builder(
                                controller: sheetScrollController,
                                itemCount: restaurants.length,
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                itemBuilder: (context, index) {
                                  final restaurant = restaurants[index];
                                  final bool isSelected = _selectedRestaurant?.placeId == restaurant.placeId;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12.0),
                                    child: GlassmorphicContainer(
                                      borderRadius: 16.0,
                                      backgroundColorWithOpacity: isSelected
                                          ? colorScheme.primaryContainer.withValues(alpha: 0.8)
                                          : colorScheme.surface.withValues(alpha: 0.95),
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary.withValues(alpha: 0.6)
                                            : colorScheme.outline.withValues(alpha: 0.1),
                                        width: isSelected ? 2.0 : 0.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(12.0),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedRestaurant = restaurant;
                                            });
                                            _moveCameraToPosition(LatLng(restaurant.lat, restaurant.lng), zoom: 17);
                                            _updateMarkers(restaurants);
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    RestaurantDetailScreen(restaurant: restaurant),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(16.0),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? colorScheme.primary.withValues(alpha: 0.1)
                                                        : colorScheme.surfaceContainerHighest,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.restaurant,
                                                    color: isSelected
                                                        ? colorScheme.primary
                                                        : colorScheme.onSurfaceVariant,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        restaurant.name,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 17,
                                                          color: isSelected
                                                              ? colorScheme.onPrimaryContainer
                                                              : colorScheme.onSurface,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      if (restaurant.rating > 0)
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.star_rounded,
                                                              color: Colors.amber.shade600,
                                                              size: 16,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              restaurant.rating.toStringAsFixed(1),
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w500,
                                                                color: isSelected
                                                                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.9)
                                                                    : colorScheme.onSurface,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Text(
                                                              '•',
                                                              style: TextStyle(
                                                                color: colorScheme.onSurfaceVariant,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Icon(
                                                              Icons.location_on,
                                                              color: isSelected
                                                                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                                                  : colorScheme.onSurfaceVariant,
                                                              size: 14,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              '5분', // This could be calculated distance
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: isSelected
                                                                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                                                                    : colorScheme.onSurfaceVariant,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      const SizedBox(height: 4),
                                                      if (restaurant.address.isNotEmpty)
                                                        Text(
                                                          restaurant.address,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: isSelected
                                                                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                                                : colorScheme.onSurfaceVariant,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.chevron_right,
                                                  color: isSelected
                                                      ? colorScheme.onPrimaryContainer.withValues(alpha: 0.6)
                                                      : colorScheme.onSurfaceVariant,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.6),
                  colorScheme.secondaryContainer.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Google Map
          GoogleMap(
            key: _mapKey,
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
            onMapCreated: _onMapCreated,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * _sheetInitialSize,
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
              _searchFocusNode.unfocus();
              if (mounted) {
                setState(() {
                  _selectedRestaurant = null;
                });
              }
              _scrollController.animateTo(
                _sheetMinSize,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
              _updateMarkers(restaurantsAsyncValue.asData?.value ?? []);
            },
          ),

          // "Search This Area" button
          if (_showSearchThisAreaButton && !_isSearchExpanded)
            Positioned(
              top: MediaQuery.of(context).padding.top + 21,
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
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    _fetchRestaurantsForCurrentMapArea();
                  },
                ),
              ),
            ),

          // Bottom sheet with integrated search bar
          _buildDraggableSheetWithSearch(context, restaurantsAsyncValue),

          Positioned(
            // Position it above the draggable sheet.
            // You might need to adjust 'bottom' based on your sheet's behavior and min height.
            // This example positions it relative to the sheet's minimum possible height.
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _buildMyLocationButton(),
          ),
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