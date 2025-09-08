import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/error/failure.dart';
import 'core/widgets/glassmorphic_container.dart';
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
        actions: [
          restaurantsAsyncValue.isLoading
              ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  // color: Colors.white, // Glassmorphism AppBar 아이콘 색상
                )),
          )
              : IconButton(
            icon: const Icon(Icons.my_location
              // , color: Colors.white // Glassmorphism AppBar 아이콘 색상
            ),
            tooltip: "내 위치 음식점 검색",
            onPressed: () async {
              try {
                final position = await ref.read(locationServiceProvider).getCurrentPosition();
                _moveCameraToPosition(LatLng(position.latitude, position.longitude));
                ref.read(restaurantListProvider.notifier).fetchRestaurantsForCurrentLocation();
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
              } catch (e) {
                if (mounted) {
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
              if (_mapController != null && _isMapReady) {
                _mapController!.getVisibleRegion().then((bounds) {
                  final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
                  final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
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
                _sheetInitialSize,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              _updateMarkers(restaurantsAsyncValue.asData?.value ?? []);
            },
            // 필요하다면 지도 스타일 변경 (예: 어두운 스타일)
            // style: await MapStyleHelper.loadMapStyle('assets/map_styles/dark_style.json'),
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
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
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

  await dotenv.load(fileName: ".env");

  await di.initDI(); // DI 컨테이너 초기화
  runApp(
    ProviderScope(
      overrides: [
        restaurantRepositoryProviderForRiverpod.overrideWithValue(
          di.sl<RestaurantRepository>(),
        ),
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
