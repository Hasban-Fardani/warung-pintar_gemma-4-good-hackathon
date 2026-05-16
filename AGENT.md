# Flutter Best Practices — AI Rules for Vibe Coding

> Target: Flutter 3.x / Dart 3.x — 2025 Edition  
> Scope: Maintainability · Scalability · Security  

---

## 1. Project Structure

### Gunakan Feature-First Architecture

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── network/
│   ├── router/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/    ← abstract
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/            ← atau riverpod/
│   │       ├── pages/
│   │       └── widgets/
│   └── home/
│       └── ...
├── shared/
│   ├── widgets/
│   └── services/
└── main.dart
```

### Rules
- Setiap fitur **self-contained**: tidak boleh import langsung dari fitur lain, hanya lewat `core/` atau `shared/`.
- `domain/` layer **zero Flutter dependency** — murni Dart.
- `data/` layer handle API, database, local storage.
- `presentation/` layer handle UI dan state.

---

## 2. Clean Architecture Layers

### Domain Layer (Pure Dart)
```dart
// entity — tidak ada fromJson/toJson di sini
class User {
  final String id;
  final String email;
  const User({required this.id, required this.email});
}

// repository interface
abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
}

// usecase
class LoginUseCase {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  Future<Either<Failure, User>> call(LoginParams params) =>
      _repository.login(params.email, params.password);
}
```

### Data Layer
```dart
// model extends entity, tambah serialization
class UserModel extends User {
  const UserModel({required super.id, required super.email});

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel(id: json['id'], email: json['email']);

  Map<String, dynamic> toJson() => {'id': id, 'email': email};
}

// repository implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  const AuthRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final model = await _remote.login(email, password);
      await _local.cacheUser(model);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

---

## 3. State Management

### Keputusan Berdasarkan Skala

| Skala | Rekomendasi | Alasan |
|-------|-------------|--------|
| Kecil (< 5 screen) | `setState` + `ValueNotifier` | Zero boilerplate |
| Medium (5–20 screen) | **Riverpod 3** | Type-safe, testable, composable |
| Besar (20+ screen) | **Riverpod 3** atau **BLoC** | Strict architecture |
| Enterprise / Tim besar | **BLoC** | Predictable, auditable, team-friendly |

> **JANGAN gunakan GetX** untuk project yang ingin maintainable jangka panjang. GetX melanggar separation of concerns dan susah di-test.

### Riverpod (Rekomendasi Default)
```dart
// provider
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<User?> build() => const AsyncValue.data(null);

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(loginUseCaseProvider).call(
        LoginParams(email: email, password: password),
      ),
    );
  }
}

// konsumsi di widget
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (user) => user != null ? const HomeScreen() : const LoginForm(),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => ErrorWidget(e.toString()),
    );
  }
}
```

### BLoC (untuk Enterprise)
```dart
// event
sealed class AuthEvent {}
final class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested(this.email, this.password);
}

// state — gunakan sealed class (Dart 3)
sealed class AuthState {}
final class AuthInitial extends AuthState {}
final class AuthLoading extends AuthState {}
final class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}
final class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
}

// bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;

  AuthBloc(this._loginUseCase) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
```

---

## 4. Dependency Injection

### Gunakan `get_it` + `injectable`
```dart
// setup
@InjectableInit()
void configureDependencies() => getIt.init();

// registrasi
@singleton
class NetworkClient { ... }

@lazySingleton
class AuthRepositoryImpl implements AuthRepository { ... }

@injectable
class LoginUseCase { ... }

// akses
final loginUseCase = getIt<LoginUseCase>();
```

### Rules DI
- `@singleton` — services yang stateful, dibuat sekali (NetworkClient, SecureStorage).
- `@lazySingleton` — dibuat hanya saat pertama kali dipakai.
- `@injectable` — dibuat baru setiap kali dibutuhkan (UseCases).
- **Jangan gunakan `GetIt` langsung di widget** — inject lewat state management.

---

## 5. Navigation

### Gunakan `go_router`
```dart
final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isLoggedIn = context.read<AuthRepository>().isLoggedIn;
    if (!isLoggedIn && state.matchedLocation != '/login') return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomePage()),
        GoRoute(
          path: '/profile/:id',
          builder: (_, state) => ProfilePage(id: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
```

### Rules
- Gunakan `GoRouter` untuk deep linking dan type-safe navigation.
- Implementasi `redirect` untuk auth guard di router level, bukan di setiap screen.
- Hindari `Navigator.push` langsung di widget — centralize di router.

---

## 6. Network Layer

### Struktur dengan Dio + Interceptor
```dart
@singleton
class NetworkClient {
  late final Dio _dio;

  NetworkClient(this._tokenStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    _dio.interceptors.addAll([
      AuthInterceptor(_tokenStorage),
      LoggingInterceptor(),
      RetryInterceptor(_dio),
    ]);
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // refresh token logic
      final refreshed = await _refreshToken();
      if (refreshed) {
        return handler.resolve(await _retry(err.requestOptions));
      }
    }
    handler.next(err);
  }
}
```

### Rules
- Semua API call lewat repository — **tidak ada `Dio` di widget atau BLoC/Riverpod**.
- Selalu implementasi timeout.
- Implementasi retry interceptor untuk transient errors.
- Parse error response di data layer, jangan expose `DioException` ke domain.

---

## 7. Error Handling

### Gunakan `Either` dari `fpdart` atau `dartz`
```dart
// failure hierarchy
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('No internet connection');
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// exception di data layer
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
}

// handling di repository
try {
  final data = await _remote.fetchData();
  return Right(data);
} on ServerException catch (e) {
  return Left(ServerFailure(e.message));
} on SocketException {
  return Left(const NetworkFailure());
}
```

### Global Error Handler
```dart
// di main.dart
FlutterError.onError = (details) {
  FirebaseCrashlytics.instance.recordFlutterFatalError(details);
};

PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

---

## 8. Security

### 8.1 Jangan Simpan Secret di Client

```
❌ DILARANG:
- Hardcode API key di Dart file
- Simpan API key di .env yang di-bundle APK
- Commit .env ke Git

✅ WAJIB:
- Semua secret key di backend proxy
- Gunakan --dart-define untuk build-time config (bukan secret)
- Gunakan firebase_remote_config untuk config dinamis
```

### 8.2 Secure Storage
```dart
// JANGAN gunakan SharedPreferences untuk data sensitif
// Gunakan flutter_secure_storage

@singleton
class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveToken(String token) =>
      _storage.write(key: 'access_token', value: token);

  Future<String?> getToken() => _storage.read(key: 'access_token');

  Future<void> clearAll() => _storage.deleteAll();
}
```

### 8.3 Certificate Pinning
```dart
// untuk app yang butuh keamanan tinggi (fintech, healthcare)
final dio = Dio();
(dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) {
    // validasi SHA256 fingerprint
    return cert.sha256.toString() == expectedFingerprint;
  };
  return client;
};
```

### 8.4 Input Validation
```dart
// validasi di presentation layer (UX)
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email wajib diisi';
  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Format email tidak valid';
  }
  return null;
}

// sanitasi sebelum kirim ke API
String sanitizeInput(String input) => input.trim();
```

### 8.5 Obfuscation (Wajib Production)
```yaml
# pubspec.yaml — tambah di build config
# Jalankan:
# flutter build apk --obfuscate --split-debug-info=build/debug-info
```

### 8.6 Root/Jailbreak Detection
```dart
// gunakan package: flutter_jailbreak_detection
final isCompromised = await FlutterJailbreakDetection.jailbroken;
if (isCompromised) {
  // log ke analytics, tampilkan warning, atau exit
}
```

---

## 9. Performance

### 9.1 Widget Optimization
```dart
// ✅ Gunakan const constructor semaksimal mungkin
const Text('Hello');
const SizedBox(height: 16);
const EdgeInsets.all(16);

// ✅ Pisah widget besar menjadi komponen kecil
// Jangan taruh semua UI dalam satu build() method

// ❌ Hindari logic berat di build()
Widget build(BuildContext context) {
  final sorted = items.sort(...); // ❌ dipanggil setiap rebuild
  return ...;
}

// ✅ Hitung di initState atau state management
void initState() {
  _sortedItems = widget.items.sorted(...);
}
```

### 9.2 ListView Optimization
```dart
// ✅ Untuk list panjang — gunakan builder
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
);

// ✅ Untuk item dengan tipe berbeda
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return switch (items[index]) {
      HeaderItem() => HeaderWidget(item: items[index] as HeaderItem),
      DataItem() => DataWidget(item: items[index] as DataItem),
    };
  },
);
```

### 9.3 Image Optimization
```dart
// ✅ Selalu gunakan cached_network_image
CachedNetworkImage(
  imageUrl: url,
  placeholder: (_, __) => const ShimmerWidget(),
  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
  memCacheWidth: 300, // downscale di memory
);
```

### 9.4 Animation
```dart
// ✅ Gunakan AnimatedBuilder dengan child yang tidak bergantung animasi
AnimatedBuilder(
  animation: _controller,
  child: const ExpensiveChild(), // hanya dibangun sekali
  builder: (context, child) => Transform.rotate(
    angle: _controller.value,
    child: child,
  ),
);

// ❌ Hindari clipping di dalam animasi yang berjalan terus
```

### 9.5 Async Best Practices
```dart
// ✅ Selalu dispose controller dan stream subscription
class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = stream.listen(_onData);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ✅ Hindari FutureBuilder yang rebuild setiap kali parent rebuild
// Simpan future di state, bukan langsung di build()
late final _future = _fetchData(); // dipanggil sekali
```

---

## 10. Code Quality

### 10.1 analysis_options.yaml (Wajib)
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Style
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_final_fields: true
    prefer_final_locals: true
    avoid_print: true

    # Design
    prefer_single_quotes: true
    require_trailing_commas: true
    sort_constructors_first: true

    # Safety
    avoid_dynamic_calls: true
    avoid_type_to_string: true
    cancel_subscriptions: true
    close_sinks: true
    unawaited_futures: true

analyzer:
  errors:
    invalid_annotation_target: ignore
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
```

### 10.2 Naming Convention
```
File        : snake_case.dart         → auth_repository.dart
Class       : PascalCase              → AuthRepository
Variable    : camelCase               → authRepository
Constant    : camelCase atau SCREAMING → maxRetries, MAX_RETRIES
Private     : _camelCase              → _repository
Extension   : PascalCase on Type      → StringExtension
```

### 10.3 Gunakan Freezed untuk Data Classes
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? displayName,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// Otomatis dapat: copyWith, ==, hashCode, toString, fromJson, toJson
```

### 10.4 Extension untuk Reusability
```dart
extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}

extension StringExtension on String {
  bool get isValidEmail =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
```

---

## 11. Testing

### Piramida Testing Flutter
```
         ┌──────────┐
         │Integration│  ← sedikit, lambat, test end-to-end
         ├───────────┤
         │  Widget   │  ← medium, test UI + interaksi
         ├───────────┤
         │   Unit    │  ← banyak, cepat, test logic
         └───────────┘
```

### Unit Test (Domain & Data Layer)
```dart
group('LoginUseCase', () {
  late LoginUseCase sut;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    sut = LoginUseCase(mockRepository);
  });

  test('should return User when login succeeds', () async {
    // arrange
    when(() => mockRepository.login(any(), any()))
        .thenAnswer((_) async => Right(tUser));

    // act
    final result = await sut(LoginParams(email: tEmail, password: tPassword));

    // assert
    expect(result, Right(tUser));
    verify(() => mockRepository.login(tEmail, tPassword)).called(1);
  });
});
```

### Widget Test
```dart
testWidgets('LoginPage shows error when login fails', (tester) async {
  // arrange
  final container = ProviderContainer(overrides: [
    authNotifierProvider.overrideWith(() => MockAuthNotifier()),
  ]);

  // act
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const LoginPage()),
  );
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();

  // assert
  expect(find.text('Email atau password salah'), findsOneWidget);
});
```

### Rules Testing
- Gunakan `mocktail` (lebih mudah dari `mockito` untuk Dart null-safety).
- Minimal 80% coverage untuk domain dan data layer.
- Widget test untuk halaman kritis (login, checkout, payment).
- Integration test untuk user journey utama.

---

## 12. CI/CD

### GitHub Actions Minimal
```yaml
# .github/workflows/flutter_ci.yml
name: Flutter CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Test with coverage
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
          cache: true
      - run: flutter pub get
      - run: |
          flutter build apk \
            --release \
            --obfuscate \
            --split-debug-info=build/debug-info \
            --dart-define=API_URL=${{ secrets.API_URL }}
```

### Rules CI/CD
- Secrets (API_URL, signing keys) **hanya di GitHub Secrets / CI environment variable**, tidak di repo.
- `flutter analyze --fatal-infos` wajib — tidak boleh ada warning lolos ke main.
- Jalankan test sebelum build.
- Cache Flutter SDK dan pub dependencies untuk mempercepat pipeline.

---

## 13. App Configuration

### Pisahkan Config per Environment
```dart
// lib/core/config/app_config.dart
enum Flavor { development, staging, production }

class AppConfig {
  static late final Flavor flavor;
  static late final String baseUrl;
  static late final String appName;

  static void initialize() {
    const flavorStr = String.fromEnvironment('FLAVOR', defaultValue: 'development');
    flavor = Flavor.values.byName(flavorStr);

    switch (flavor) {
      case Flavor.development:
        baseUrl = 'https://dev-api.example.com';
        appName = '[DEV] MyApp';
      case Flavor.staging:
        baseUrl = 'https://staging-api.example.com';
        appName = '[STG] MyApp';
      case Flavor.production:
        baseUrl = 'https://api.example.com';
        appName = 'MyApp';
    }
  }
}

// main.dart
void main() {
  AppConfig.initialize();
  runApp(const MyApp());
}
```

```bash
# Run dengan flavor
flutter run --dart-define=FLAVOR=development
flutter build apk --dart-define=FLAVOR=production --dart-define=API_URL=https://api.example.com
```

---

## 14. Recommended Packages

### Core
| Package | Fungsi |
|---------|--------|
| `riverpod` / `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `get_it` + `injectable` | Dependency injection |
| `dio` | HTTP client |
| `freezed` | Immutable data classes |
| `fpdart` | Functional programming (Either, Option) |
| `json_serializable` | JSON serialization |

### Security & Storage
| Package | Fungsi |
|---------|--------|
| `flutter_secure_storage` | Encrypted local storage |
| `encrypt` | AES encryption |
| `flutter_jailbreak_detection` | Root/jailbreak detection |

### UI & UX
| Package | Fungsi |
|---------|--------|
| `cached_network_image` | Image caching |
| `shimmer` | Loading skeleton |
| `flutter_svg` | SVG rendering |

### Testing
| Package | Fungsi |
|---------|--------|
| `mocktail` | Mocking |
| `bloc_test` | Test BLoC |
| `network_image_mock` | Mock network images di test |

### Dev Tools
| Package | Fungsi |
|---------|--------|
| `flutter_lints` | Lint rules |
| `very_good_analysis` | Strict lint (opsional) |

---

## 15. Anti-Patterns — Jangan Lakukan Ini

```
❌ Business logic di Widget
❌ Dart model class dengan 'dynamic' field
❌ API call langsung di build() method
❌ SharedPreferences untuk token / password
❌ GetX untuk project tim / jangka panjang
❌ Hardcode string (gunakan constants / l10n)
❌ Tidak dispose controller, stream, animation
❌ Nested setState yang dalam
❌ Satu file > 300 baris (pecah menjadi modul)
❌ Tidak ada error handling di repository
❌ Commit API key / secret ke Git
❌ Navigator.push di dalam BLoC / Notifier
❌ Menggunakan 'as' cast tanpa try-catch
❌ print() di production code (gunakan logger package)
❌ BuildContext disimpan di luar widget lifecycle
```

---

## 16. Dart 3 Modern Features — Wajib Digunakan

```dart
// Sealed class untuk exhaustive pattern matching
sealed class AuthState {}
final class AuthLoading extends AuthState {}
final class AuthSuccess extends AuthState { final User user; ... }
final class AuthFailure extends AuthState { final String message; ... }

// Switch expression dengan pattern matching
String getMessage(AuthState state) => switch (state) {
  AuthLoading() => 'Memuat...',
  AuthSuccess(:final user) => 'Selamat datang, ${user.email}',
  AuthFailure(:final message) => 'Error: $message',
};

// Records untuk multiple return
(String name, int age) getUserInfo() => ('Hasban', 19);
final (name, age) = getUserInfo();

// Null-aware operators — selalu gunakan
final name = user?.profile?.displayName ?? 'Anonymous';
list?.forEach(print);
```
## 17. Git Workflow & Commit Hygiene (Mandatory)

### Atomic Commits
- One task/phase = one commit. Never bundle unrelated changes.
- Format: `feat: Phase [X] - [concise description]` or `fix: [component] - [issue]`
- Local-only during development: `git commit` allowed, `git push` strictly forbidden until explicitly approved.

### Pre-Commit Gate
- MUST pass `flutter analyze --fatal-infos` before staging. Zero warnings allowed.
- MUST pass `dart format --set-exit-if-changed .`
- Zero broken imports, zero syntax errors, zero unhandled async exceptions.
- If any check fails: fix immediately. Do not commit broken code.

### Post-Commit Diff Verification
- Run `git diff HEAD~1..HEAD --stat` and review output.
- Confirm only intended files were modified/created.
- Check for accidental deletions, whitespace noise, or style drift in unrelated files.
- If diff contains out-of-scope changes or linter violations: `git commit --amend` or `git reset --soft HEAD~1`, fix, and recommit.

### Anti-Patterns (Git)
- ❌ `git push` before phase verification & diff review
- ❌ Monolithic commits mixing UI, DB, AI, and router logic
- ❌ Committing with failing `flutter analyze` or `dart format`
- ❌ Leaving `print()`, debug `TODO:`, or mock data without clear `// HACK:` or `// DEV:` tags
- ❌ Ignoring merge conflicts or auto-resolving without manual review

### LLM Execution Rule
- When generating or modifying code, simulate this workflow internally: analyze → format → stage → commit → diff-verify → report.
- Never skip verification steps. If a command fails, output the exact error, propose a surgical fix, and STOP. Wait for explicit approval before proceeding.

---

*Last updated: May 2026 | Flutter 3.x / Dart 3.x*