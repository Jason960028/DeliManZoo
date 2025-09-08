import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/error/failure.dart';
import 'core/widgets/glassmorphic_container.dart';
import 'firebase_options.dart'; // flutterfire configure로 생성된 파일
import 'injection_container.dart' as di; // DI 컨테이너 임포트
import 'features/restaurant/domain/entities/restaurant_entity.dart';
import 'features/restaurant/domain/repositories/restaurant_repository.dart';
import 'features/restaurant/presentation/providers/restaurant_providers.dart';
// Auth imports
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';

// HomeScreen
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng _initialPosition = const LatLng(37.5665, 126.9780); // 서울 시청
  bool _isMapReady = false;
  final DraggableScrollableController _scrollController = DraggableScrollableController();
  RestaurantEntity? _selectedRestaurant;
  bool _showSearchThisAreaButton = false; // "Search This Area" 버튼 표시 여부
  LatLng? _lastIdleMapCenter;

  // DraggableScrollableSheet의 최소/초기 크기 (상수로 정의하여 여러 곳에서 사용)
  static const double _sheetMinSize = 0.15;
  static const double _sheetInitialSize = 0.15;
  static const double _sheetSnapMidSize = 0.5;
  static const double _sheetMaxSize = 0.8;


  @override
  void initState() {
    super.initState();
  }

  void _fetchRestaurantsForCurrentMapArea() {
    if (_mapController != null && _isMapReady) {
      _mapController!.getVisibleRegion().then((bounds) {
        final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
        final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
        print("Fetching restaurants for area: $centerLat, $centerLng");
        ref.read(restaurantListProvider.notifier).fetchRestaurantsForLocation(centerLat, centerLng);
        if (mounted) {
          setState(() {
            _showSearchThisAreaButton = false; // 검색 실행 후 버튼 숨김
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
    // 초기 데이터 로드 상태 확인 및 카메라 이동
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
      print("Error getting current location for initial map: $e");
      _moveCameraToPosition(_initialPosition); // 기본 위치로 이동
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
              _sheetSnapMidSize, // 중간 크기로 확장
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        icon: isSelected
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        zIndex: isSelected ? 1.0 : 0.0,
        onTap: () {
          setState(() {
            _selectedRestaurant = restaurant;
          });
          _moveCameraToPosition(LatLng(restaurant.lat, restaurant.lng), zoom: 16);
          _scrollController.animateTo(
            _sheetSnapMidSize, // 중간 크기로 확장
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      );
    }).toSet();

    if (mounted) { // 위젯이 여전히 마운트된 상태인지 확인
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // restaurantListProvider를 listen하여 데이터 변경 시 마커 및 선택 상태 업데이트
    ref.listen<AsyncValue<List<RestaurantEntity>>>(restaurantListProvider, (previous, next) {
      next.whenData((restaurants) {
        _updateMarkers(restaurants);
        // 선택된 식당이 새 목록에 없으면 선택 해제
        if (_selectedRestaurant != null && !restaurants.any((r) => r.placeId == _selectedRestaurant!.placeId)) {
          if (mounted) {
            setState(() {
              _selectedRestaurant = null;
            });
          }
        }
      });
    });

    // restaurantListProvider를 watch하여 UI에 데이터 상태 반영
    final restaurantsAsyncValue = ref.watch(restaurantListProvider);
    final colorScheme = Theme.of(context).colorScheme; // 현재 테마의 ColorScheme 가져오기
    final darkContentColor = colorScheme.onSurface; // 테마의 표면 위 콘텐츠 색 (보통 어두움)
    final darkMutedContentColor = colorScheme.onSurfaceVariant; // 약간 더 흐린 어두운 색

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '주변 음식점',
        ),
      ),
      body: Stack(
        children: [
          // 1. 배경 (그라데이션 또는 이미지)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.6), // 테마 색상 활용
                  colorScheme.secondaryContainer.withOpacity(0.6), // 테마 색상 활용
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. GoogleMap
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
            // Glassmorphism 시트가 올라오므로, 지도 패딩은 시트 최소 높이만큼 유지
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * _sheetMinSize),
            onCameraIdle: () {
              // 지도 이동이 멈췄을 때
              if (_mapController != null && _isMapReady) {
                _mapController!.getVisibleRegion().then((bounds) {
                  final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
                  final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
                  _lastIdleMapCenter = LatLng(centerLat, centerLng); // 마지막 중심 저장

                  // 이전에 로드된 데이터가 없거나, 마지막 로드 위치와 현재 위치가 많이 다를 때 버튼 표시
                  // 또는 단순히 지도 이동이 끝나면 항상 버튼 표시 (더 간단)
                  if (mounted) {
                    setState(() {
                      _showSearchThisAreaButton = true;
                    });
                  }
                });
              }
            },
            onTap: (_) {
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
            // 필요하다면 지도 스타일 변경 (예: 어두운 스타일)
            // style: await MapStyleHelper.loadMapStyle('assets/map_styles/dark_style.json'),
          ),
          // 3. "Search This Area" 버튼
          if (_showSearchThisAreaButton)
            Positioned(
              top: 10.0, // AppBar 바로 아래 여백
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.search, color: colorScheme.onPrimary),
                  label: Text('이 지역 검색', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
                    elevation: 5,
                  ),
                  onPressed: () {
                    _fetchRestaurantsForCurrentMapArea();
                  },
                ),
              ),
            ),
          // 3. DraggableScrollableSheet with Glassmorphism
          DraggableScrollableSheet(
            controller: _scrollController,
            initialChildSize: _sheetInitialSize,
            minChildSize: _sheetMinSize,
            maxChildSize: _sheetMaxSize,
            snap: true,
            snapSizes: const [_sheetMinSize, _sheetSnapMidSize, _sheetMaxSize],
            builder: (BuildContext context, ScrollController sheetScrollController) {
              return GlassmorphicContainer(
                borderRadius: 16.0,
                blurSigmaX: 7.0, // 블러 강도 조절
                blurSigmaY: 7.0,
                backgroundColorWithOpacity: colorScheme.surface.withOpacity(0.20), // 테마 표면 색상에 투명도
                border: Border.all(color: colorScheme.onSurface.withOpacity(0.15)),
                child: restaurantsAsyncValue.when(
                  loading: () => Center(child: CircularProgressIndicator(color: Colors.white.withOpacity(0.7))),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: colorScheme.error, size: 48), // 에러 아이콘은 테마 에러색                          const SizedBox(height: 16),
                          Text(
                            error is Failure ? error.message : "목록 로딩 중 오류가 발생했습니다.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: Icon(Icons.refresh, color: colorScheme.onErrorContainer),
                            label: Text('다시 시도', style: TextStyle(color: colorScheme.onErrorContainer)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.errorContainer.withOpacity(0.8), // 에러 상황 버튼 배경
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () => ref.read(restaurantListProvider.notifier).fetchRestaurantsForCurrentLocation(),
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
                        Container( // 상단 핸들러
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
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8), // 리스트 하단 패딩
                            itemBuilder: (context, index) {
                              final restaurant = restaurants[index];
                              final bool isSelected = _selectedRestaurant?.placeId == restaurant.placeId;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                                child: GlassmorphicContainer(
                                  height: 90, // 아이템 높이 설정
                                  borderRadius: 12.0,
                                  // 선택 시 배경을 조금 더 어둡거나 강조되게, 기본은 밝은 Glass 유지
                                  backgroundColorWithOpacity: isSelected
                                      ? colorScheme.primaryContainer.withOpacity(0.5) // 선택 시 배경은 테마 색상 활용
                                      : colorScheme.surfaceContainerHighest.withOpacity(0.5), // 기본 항목 배경 (밝은 Glass)
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary // 선택 시 테두리
                                        : Colors.white.withOpacity(0.2), // 기본 테두리 (밝게)
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: InkWell(
                                      onTap: () {
                                        if (mounted) {
                                          setState(() {
                                            _selectedRestaurant = restaurant;
                                          });
                                        }
                                        _moveCameraToPosition(LatLng(restaurant.lat, restaurant.lng), zoom: 16);
                                        _updateMarkers(restaurants);
                                      },
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.restaurant,
                                              color: isSelected ? colorScheme.onPrimaryContainer : darkContentColor, // 아이콘 색상 변경
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
                                                      color: isSelected ? colorScheme.onPrimaryContainer : darkContentColor, // 텍스트 색상 변경
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
                                                              ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                                                              : darkMutedContentColor, // 부제 텍스트 색상 변경
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
                                                  Icon(Icons.star,
                                                      color: isSelected
                                                          ? colorScheme.onPrimaryContainer.withOpacity(0.9)
                                                          : Colors.amber.shade700, // 별 색상 (어두운 배경에 맞게 조정 가능)
                                                      size: 18),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    restaurant.rating.toStringAsFixed(1),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: isSelected
                                                          ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                                                          : darkContentColor, // 평점 텍스트 색상 변경
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
                                                      ? colorScheme.onPrimaryContainer.withOpacity(0.6)
                                                      : darkMutedContentColor, // "평점 없음"
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
              );
            },
          ),

          // (선택 사항) AppBar 영역에 별도의 Glassmorphic 배경을 추가하려면 여기에 Positioned 위젯 사용
          // Positioned(
          //   top: 0,
          //   left: 0,
          //   right: 0,
          //   child: GlassmorphicContainer(
          //     height: kToolbarHeight + MediaQuery.of(context).padding.top,
          //     borderRadius: 0, // AppBar는 보통 각지지 않음
          //     backgroundColorWithOpacity: colorScheme.surface.withOpacity(0.15),
          //     child: SizedBox.shrink(), // 내용은 실제 AppBar가 채우도록
          //   ),
          // ),
        ],
      ),
    );
  }

// ... (dispose 메서드 등 나머지 _HomeScreenState 코드) ...



  @override
  void dispose() {
    _mapController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// SearchScreen, ProfileScreen (변경 없음 - 이전 코드와 동일)
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) { /* ... */ return Scaffold(appBar: AppBar(title: const Text('검색')), body: const Center(child: Placeholder(child: Text('검색 화면 구현 예정', textAlign: TextAlign.center)))); }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Header
                GlassmorphicContainer(
                  borderRadius: 20.0,
                  backgroundColorWithOpacity: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1.0,
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: currentUser?.photoURL != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  currentUser!.photoURL!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                      ),
                      const SizedBox(height: 16),
                      
                      // User Info
                      Text(
                        currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'User',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (currentUser?.email != null)
                        Text(
                          currentUser!.email!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // Menu Items
                GlassmorphicContainer(
                  borderRadius: 16.0,
                  backgroundColorWithOpacity: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1.0,
                  ),
                  child: Column(
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.favorite_outline,
                        title: '즐겨찾기',
                        subtitle: '저장한 맛집',
                        onTap: () {
                          // TODO: Navigate to favorites
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('즐겨찾기 기능 구현 예정')),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.history,
                        title: '최근 방문',
                        subtitle: '최근 본 맛집',
                        onTap: () {
                          // TODO: Navigate to history
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('최근 방문 기능 구현 예정')),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.settings_outlined,
                        title: '설정',
                        subtitle: '앱 설정',
                        onTap: () {
                          // TODO: Navigate to settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('설정 기능 구현 예정')),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.help_outline,
                        title: '도움말',
                        subtitle: '자주 묻는 질문',
                        onTap: () {
                          // TODO: Navigate to help
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('도움말 기능 구현 예정')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: authState.isLoading 
                        ? null 
                        : () async {
                            // Show confirmation dialog
                            final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('로그아웃'),
                                content: const Text('정말 로그아웃 하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('로그아웃'),
                                  ),
                                ],
                              ),
                            ) ?? false;

                            if (shouldLogout) {
                              await ref.read(authProvider.notifier).signOut();
                              // Navigation will be handled by AuthWrapper automatically
                            }
                          },
                    icon: authState.isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: Text(authState.isLoading ? '로그아웃 중...' : '로그아웃'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // App Version (Optional)
                Text(
                  'DeliManZoo v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Profile Menu Items
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}


// main 함수
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  await di.initDI(); // DI 컨테이너 초기화
  runApp(
    ProviderScope(
      overrides: [
        restaurantRepositoryProviderForRiverpod.overrideWithValue(
          di.sl<RestaurantRepository>(),
        ),
        authRepositoryProvider.overrideWithValue(
          di.sl<AuthRepository>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// AuthWrapper - Authentication routing logic
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        // User is signed in
        if (user != null) {
          return const MainScreen();
        }
        // User is not signed in
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => const LoginScreen(),
    );
  }
}

// MyApp 클래스 (MaterialApp 설정)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '내 주변 맛집',
      theme: ThemeData(
        // Material 3 테마 사용
        useMaterial3: true,
        // 기본 색상 스킴 (원하는 색상으로 변경 가능)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // AppBar 테마 (선택 사항)
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer, // 예시
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer, // 예시
        ),
        // ListTile 테마 (선택 사항)
        listTileTheme: ListTileThemeData(
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

// MainScreen (BottomNavigationBar 관리)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: '지도', // 라벨 변경
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: '검색',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '내 정보', // 라벨 변경
          ),
        ],
        currentIndex: _selectedIndex,
        // Material3에서는 selectedItemColor 대신 BottomNavigationBarTheme을 사용하거나,
        // NavigationBar 위젯을 사용하는 것이 권장됩니다.
        // 여기서는 간단하게 Theme에서 가져오도록 시도하거나 기본값을 사용합니다.
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        onTap: _onItemTapped,
        // type: BottomNavigationBarType.fixed, // 아이템이 3개일 때는 기본적으로 fixed
      ),
    );
  }
}

