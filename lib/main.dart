import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
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
  // _currentLat, _currentLng는 더 이상 주요 상태가 아님. 지도 연동 시 다시 사용될 수 있음.

  @override
  void initState() {
    super.initState();
    // build 메서드에서 초기 위치를 가져오므로, 여기서 명시적으로 호출할 필요는 없음.
    // 만약 Provider의 build가 실패하여 UI에 오류가 표시된 후 사용자가 재시도하고 싶다면,
    // 아래와 같은 로직을 새로고침 버튼에 연결할 수 있습니다.
  }

  // 지도 이동 시 호출될 메서드는 지도 연동 후 사용
  // void _onMapMoved(double newLat, double newLng) { ... }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsyncValue = ref.watch(restaurantListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈 (내 주변 음식점)'), // 타이틀 변경
        actions: [
          // 현재 위치 기반 새로고침 버튼
          restaurantsAsyncValue.isLoading // 로딩 중일때는 버튼 비활성화 또는 다른 아이콘 표시
              ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)
            ),
          )
              : IconButton(
            icon: const Icon(Icons.my_location), // 아이콘 변경
            tooltip: "내 위치 새로고침",
            onPressed: () => ref
                .read(restaurantListProvider.notifier)
                .fetchRestaurantsForCurrentLocation(),
          ),
          // 임시: 지도 이동 시뮬레이션 버튼 (나중에 실제 지도로 대체)
          // IconButton(
          //   icon: const Icon(Icons.location_searching),
          //   onPressed: () => _onMapMoved(37.4979, 127.0276), // 강남역으로 이동 (예시)
          // )
        ],
      ),
      body: Center(
        child: restaurantsAsyncValue.when(
          data: (restaurants) {
            // ... (기존 ListView.builder UI는 동일) ...
            print("UI Update - Restaurants count: ${restaurants.length}"); // <--- 디버깅 로그 추가
            if (restaurants.isNotEmpty) {
              print("First restaurant name: ${restaurants.first.name}"); // <--- 디버깅 로그 추가
            }

            if (restaurants.isEmpty) {
              return const Text('주변에 음식점이 없습니다. 다른 곳에서 검색해보세요.', style: TextStyle(fontSize: 16), textAlign: TextAlign.center,);
            }
            return ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: restaurant.photoReference != null
                    // 실제로는 Image.network 등으로 사진 표시 (Photos API 필요)
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
                    // onTap: () {
                    //   // 상세 페이지로 이동하는 로직 구현 예정
                    //   print('${restaurant.name} 선택됨');
                    // },
                  ),
                );
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) {
            print("Error in UI: $error, StackTrace: $stackTrace");
            String errorMessage = "음식점 정보를 불러오는데 실패했습니다.";
            if (error is Failure) {
              errorMessage = error.message;
            } else if (error is String) {
              errorMessage = error;
            }
            // 위치 권한 오류 시 사용자에게 설정으로 이동하도록 안내
            if (errorMessage.contains("위치 권한이 영구적으로 거부되었습니다")) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Geolocator.openAppSettings(); // 앱 설정 화면으로 이동
                      },
                      child: const Text('앱 설정으로 이동'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton( // 새로고침 버튼 추가
                      onPressed: () => ref
                          .read(restaurantListProvider.notifier)
                          .fetchRestaurantsForCurrentLocation(),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column( // 다시 시도 버튼을 위해 Column 사용
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(restaurantListProvider.notifier)
                        .fetchRestaurantsForCurrentLocation(),
                    child: const Text('다시 시도'),
                  ),
                ],
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

