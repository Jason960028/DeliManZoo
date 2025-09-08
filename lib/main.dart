import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // flutterfire configure로 생성된 파일

// 각 탭에 해당하는 Placeholder 스크린 정의
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('홈 (지도)')),
      body: const Center(
        child: Placeholder(
          child: Text('지도 화면 구현 예정', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

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


void main() async {
  // Flutter 엔진과 위젯 바인딩을 초기화합니다.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 앱을 초기화합니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '음식점 리뷰 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue, // 앱의 기본 색상 테마
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 현재 선택된 탭의 인덱스

  // 각 탭에 해당하는 위젯 (스크린) 리스트
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  // 탭이 선택되었을 때 호출될 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 선택된 탭에 해당하는 화면을 body에 표시
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined), // 지도 아이콘 (또는 home)
            activeIcon: Icon(Icons.map),    // 활성화된 지도 아이콘
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
        currentIndex: _selectedIndex, // 현재 선택된 탭 인덱스
        selectedItemColor: Colors.amber[800], // 선택된 아이템 색상
        onTap: _onItemTapped, // 탭 선택 시 호출될 함수
      ),
    );
  }
}
