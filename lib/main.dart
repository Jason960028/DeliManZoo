import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/error/failure.dart';
import 'firebase_options.dart'; // flutterfire configure로 생성된 파일
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod 임포트
import 'injection_container.dart' as di; // DI 컨테이너 임포트
import 'features/restaurant/domain/repositories/restaurant_repository.dart'; // Repository 인터페이스
import 'features/restaurant/domain/entities/restaurant_entity.dart'; // Entity
import 'features/restaurant/domain/repositories/restaurant_repository.dart'; // Repository 인터페이스
import 'features/restaurant/presentation/providers/restaurant_providers.dart';
// HomeScreen: API 호출 및 결과 표시를 위해 StatefulWidget으로 변경
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<RestaurantEntity> _restaurants = [];
  bool _isLoading = false;
  String? _errorMessage;

  double _currentLat = 37.5665;
  double _currentLng = 126.9780;

  @override
  void initState() {
    super.initState();
  }

  // 지도 이동 시 호출될 메서드 (예시)
  void _onMapMoved(double newLat, double newLng) {
    setState(() {
      _currentLat = newLat;
      _currentLng = newLng;
    });
    // 지도 이동이 끝나면 해당 위치의 음식점 데이터를 새로고침
    ref.read(restaurantListProvider.notifier).fetchRestaurantsForLocation(newLat, newLng);
    print("Map moved to: $newLat, $newLng. Fetching new restaurants.");
  }

  Future<void> _fetchNearbyRestaurants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = di.sl<RestaurantRepository>();
      // 예시 위도와 경도 (실제로는 사용자 위치나 검색 위치를 사용해야 함)
      // 예: 서울 시청 근처
      const double lat = 37.5665;
      const double lng = 126.9780;

      final result = await repository.getNearbyRestaurants(lat, lng);

      result.fold(
            (failure) {
          // 오류 처리
          if (mounted) { // 위젯이 아직 화면에 마운트되어 있을 때만 setState 호출
            print("API 호출 실패: ${failure.message}");
            setState(() {
              _errorMessage = failure.message;
              _restaurants = [];
              _isLoading = false;
            });
          }
        },
            (restaurants) {
          // 성공 처리
          if (mounted) { // 위젯이 아직 화면에 마운트되어 있을 때만 setState 호출
            print("API 호출 성공: ${restaurants.length}개의 음식점 발견");
            // for (var restaurant in restaurants) {
            //   print("이름: ${restaurant.name}, 주소: ${restaurant.address}, 평점: ${restaurant.rating}");
            // }
            setState(() {
              _restaurants = restaurants;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      // RepositoryImpl에서 예외를 Failure로 변환하지 못한 경우
      if (mounted) { // 위젯이 아직 화면에 마운트되어 있을 때만 setState 호출
        print("알 수 없는 오류 발생: $e");
        setState(() {
          _errorMessage = "알 수 없는 오류가 발생했습니다.";
          _restaurants = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // restaurantListProvider를 watch하여 상태 변화를 감지하고 UI를 다시 빌드
    final restaurantsAsyncValue = ref.watch(restaurantListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈 (주변 음식점 - Riverpod)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            // 현재 위치로 데이터 다시 가져오기
            onPressed: () => ref.read(restaurantListProvider.notifier).fetchRestaurantsForLocation(_currentLat, _currentLng),
          ),
          // 임시: 지도 이동 시뮬레이션 버튼
          IconButton(
            icon: const Icon(Icons.location_searching),
            onPressed: () => _onMapMoved(37.4979, 127.0276), // 강남역으로 이동 (예시)
          )
        ],
      ),
      body: Center(
        // AsyncValue를 사용하여 로딩, 데이터, 오류 상태를 쉽게 처리
        child: restaurantsAsyncValue.when(
          data: (restaurants) {
            if (restaurants.isEmpty) {
              return const Text('주변에 음식점이 없습니다.', style: TextStyle(fontSize: 16));
            }
            return ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: restaurant.photoReference != null
                    // 실제로는 Image.network 등으로 사진 표시
                        ? CircleAvatar(child: Icon(Icons.image), backgroundColor: Colors.grey[300])
                        : Icon(Icons.restaurant, color: Theme.of(context).primaryColor),
                    title: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(restaurant.address),
                        if (restaurant.phoneNumber != null && restaurant.phoneNumber!.isNotEmpty)
                          Text('전화: ${restaurant.phoneNumber}'),
                      ],
                    ),
                    trailing: restaurant.rating > 0
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 14)),
                      ],
                    )
                        : const Text('평점 없음', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    isThreeLine: restaurant.phoneNumber != null && restaurant.phoneNumber!.isNotEmpty,
                  ),
                );
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) {
            print("Error in UI: $error");
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '오류 발생: ${error is Failure ? error.message : error.toString()}', // Failure 객체면 message 사용
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
    );
  }
}


// SearchScreen: 변경 없음
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('검색')),
      body: const Center(
        child: Placeholder(
          child: Text('검색 화면 구현 예정', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

// ProfileScreen: 변경 없음
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: const Center(
        child: Placeholder(
          child: Text('프로필 화면 구현 예정', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

// main 함수: 변경 없음
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.initDI();
  runApp(
    ProviderScope( // 앱 전체를 ProviderScope로 감싸기
      overrides: [
        // GetIt으로 생성된 RestaurantRepository 인스턴스를
        // restaurantRepositoryProviderForRiverpod에 제공합니다.
        restaurantRepositoryProviderForRiverpod.overrideWithValue(
          di.sl<RestaurantRepository>(), // GetIt에서 RestaurantRepository 가져오기
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// MyApp 클래스: 변경 없음
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '음식점 리뷰 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// MainScreen (BottomNavigationBar 관리): 변경 없음
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // 수정된 HomeScreen 사용
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
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: '검색',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '내 프로필',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

