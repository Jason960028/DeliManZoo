import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/error/failure.dart';
import 'firebase_options.dart'; // flutterfire configure로 생성된 파일
import 'injection_container.dart' as di; // DI 컨테이너 임포트
import 'features/restaurant/domain/entities/restaurant_entity.dart';
import 'features/restaurant/domain/repositories/restaurant_repository.dart';
import 'features/restaurant/presentation/providers/restaurant_providers.dart';
import 'core/services/location_service.dart'; // LocationService Provider를 위해

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

  // DraggableScrollableSheet의 최소/초기 크기 (상수로 정의하여 여러 곳에서 사용)
  static const double _sheetMinSize = 0.15;
  static const double _sheetInitialSize = 0.15;
  static const double _sheetSnapMidSize = 0.5;
  static const double _sheetMaxSize = 0.8;


  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 음식점'),
        actions: [
          restaurantsAsyncValue.isLoading
              ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
          )
              : IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: "내 위치 음식점 검색",
            onPressed: () async {
              try {
                final position = await ref.read(locationServiceProvider).getCurrentPosition();
                _moveCameraToPosition(LatLng(position.latitude, position.longitude));
                ref.read(restaurantListProvider.notifier).fetchRestaurantsForCurrentLocation();
                if (mounted) {
                  setState(() { _selectedRestaurant = null; });
                }
                _scrollController.animateTo(
                  _sheetInitialSize, // 시트 최소화
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } catch (e) {
                if(mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('현재 위치를 가져올 수 없습니다: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
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
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * _sheetMinSize),
            onCameraIdle: () {
              if (_mapController != null && _isMapReady) { // _isMapReady 조건 추가
                _mapController!.getVisibleRegion().then((bounds) {
                  final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
                  final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
                  print("Camera Idle at: $centerLat, $centerLng. Fetching restaurants.");
                  ref.read(restaurantListProvider.notifier).fetchRestaurantsForLocation(centerLat, centerLng);
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
                _sheetInitialSize, // 시트 최소화
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              _updateMarkers(restaurantsAsyncValue.asData?.value ?? []);
            },
          ),
          DraggableScrollableSheet(
            controller: _scrollController,
            initialChildSize: _sheetInitialSize,
            minChildSize: _sheetMinSize,
            maxChildSize: _sheetMaxSize,
            snap: true,
            snapSizes: const [_sheetMinSize, _sheetSnapMidSize, _sheetMaxSize],
            builder: (BuildContext context, ScrollController sheetScrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: restaurantsAsyncValue.when(
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            error is Failure ? error.message : "목록 로딩 오류: $error",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref.read(restaurantListProvider.notifier).fetchRestaurantsForCurrentLocation(),
                            child: const Text('다시 시도'),
                          )
                        ],
                      ),
                    ),
                  ),
                  data: (restaurants) {
                    if (restaurants.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('주변에 표시할 음식점이 없습니다.'),
                        ),
                      );
                    }
                    return ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.symmetric(vertical: 10.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: sheetScrollController,
                              itemCount: restaurants.length,
                              itemBuilder: (context, index) {
                                final restaurant = restaurants[index];
                                final bool isSelected = _selectedRestaurant?.placeId == restaurant.placeId;
                                return Material(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Colors.transparent,
                                  child: ListTile(
                                    leading: restaurant.photoReference != null
                                        ? CircleAvatar(
                                      backgroundColor: Colors.grey[300],
                                      child: Icon(Icons.image, color: Colors.grey[600]),
                                    )
                                        : Icon(
                                      Icons.restaurant,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.onPrimaryContainer
                                          : Theme.of(context).colorScheme.primary,
                                    ),
                                    title: Text(
                                      restaurant.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      restaurant.address,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                                            : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: restaurant.rating > 0
                                        ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star,
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.9)
                                                : Colors.amber,
                                            size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          restaurant.rating.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                                                : null,
                                          ),
                                        ),
                                      ],
                                    )
                                        : Text(
                                      '평점 없음',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6)
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    onTap: () {
                                      if (mounted) {
                                        setState(() {
                                          _selectedRestaurant = restaurant;
                                        });
                                      }
                                      _moveCameraToPosition(LatLng(restaurant.lat, restaurant.lng), zoom: 16);
                                      _updateMarkers(restaurants); // 선택된 마커 색상 변경 위해 호출
                                      // 상세 화면으로 이동 로직 (다음 단계에서 구현)
                                      print('ListTile Tapped: ${restaurant.name}');
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // 아래 부분은 DraggableScrollableSheet 내부에서 로딩/오류를 처리하므로,
          // 중복 표시될 수 있어 주석 처리하거나 제거하는 것을 권장합니다.
          // 만약 전체 화면 초기 로딩 등을 특별히 처리하고 싶다면, 조건부로 표시할 수 있습니다.
          // restaurantsAsyncValue.when(
          //   loading: () => const Center(child: CircularProgressIndicator()),
          //   error: (error, stack) => Positioned(...),
          //   data: (restaurants) {
          //     if (restaurants.isEmpty && !restaurantsAsyncValue.isLoading) {
          //       return Center(...);
          //     }
          //     return const SizedBox.shrink();
          //   },
          // ),
        ],
      ),
    );
  }

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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) { /* ... */ return Scaffold(appBar: AppBar(title: const Text('내 프로필')), body: const Center(child: Placeholder(child: Text('프로필 화면 구현 예정', textAlign: TextAlign.center))));}
}


// main 함수
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.initDI(); // DI 컨테이너 초기화
  runApp(
    ProviderScope(
      overrides: [
        restaurantRepositoryProviderForRiverpod.overrideWithValue(
          di.sl<RestaurantRepository>(),
        ),
        // LocationService는 자체적으로 의존성이 없으므로,
        // locationServiceProvider가 직접 생성하도록 두거나 여기서 override할 수도 있습니다.
        // 예: locationServiceProvider.overrideWithValue(LocationService()),
        // 하지만 RestaurantListNotifier에서 ref.read(locationServiceProvider)로 직접 생성하는 방식도 괜찮습니다.
      ],
      child: const MyApp(),
    ),
  );
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
      home: const MainScreen(),
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
