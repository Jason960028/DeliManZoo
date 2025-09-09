import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'features/restaurant/domain/repositories/restaurant_repository.dart';
import 'features/restaurant/presentation/providers/restaurant_providers.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/profile_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/auth/presentation/widgets/auth_wrapper.dart';
import 'l10n/app_localizations.dart';

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

// MyApp 클래스 (MaterialApp 설정)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '내 주변 맛집',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ko'), // Korean
      ],
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
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

