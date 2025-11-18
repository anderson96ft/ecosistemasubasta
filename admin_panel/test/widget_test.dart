// test/widget_test.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:admin_panel/core/models/user_model.dart';
import 'package:admin_panel/core/repositories/auth_repository.dart';
import 'package:admin_panel/features/auth/screens/login_screen.dart';
import 'package:admin_panel/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:admin_panel/main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'firebase_mock.dart'; // Importa el archivo de mock de Firebase

// 1. Creamos una clase "falsa" (mock) de nuestro AuthRepository.
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  // Declaramos las variables que usaremos en los tests.
  late AuthRepository mockAuthRepository;
  const mockUser = UserModel(id: '123', email: 'test@test.com');
  const mockAdmin = UserModel(id: 'admin123', email: 'admin@test.com');

  // 2. `setUp` se ejecuta antes de cada test.
  setUp(() {
    // --- INICIALIZACIÓN DE FIREBASE PARA TESTS ---
    // Esto simula la llamada a Firebase.initializeApp()
    setupFirebaseAuthMocks();
    // -------------------------------------------
    mockAuthRepository = MockAuthRepository();
  });

  group('Admin Panel App Logic', () {
    testWidgets('Muestra LoginScreen cuando el usuario no está autenticado',
        (WidgetTester tester) async {
      // 3. Definimos el comportamiento del mock: devuelve un stream con un usuario vacío.
      when(() => mockAuthRepository.user).thenAnswer(
        (_) => Stream.value(const UserModel(id: '')),
      );

      // 4. Construimos la app con nuestro repositorio falso.
      //    Envolvemos MyApp en un RepositoryProvider para inyectar el mock.
      await tester.pumpWidget(
        RepositoryProvider<AuthRepository>.value(
          value: mockAuthRepository,
          child: const MyApp(),
        ),
      );

      // 5. Esperamos a que la UI se estabilice.
      await tester.pumpAndSettle();

      // 6. Verificamos que se muestra la LoginScreen.
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });

    testWidgets('Muestra DashboardScreen cuando el usuario está autenticado Y es admin',
        (WidgetTester tester) async {
      // 3. Comportamiento del mock:
      // - Devuelve un stream con un usuario admin.
      // - Cuando se llame a `isAdmin` con el ID del admin, devuelve `true`.
      when(() => mockAuthRepository.user).thenAnswer((_) => Stream.value(mockAdmin));
      when(() => mockAuthRepository.isAdmin(userId: mockAdmin.id)).thenAnswer((_) async => true);
      when(() => mockAuthRepository.logOut()).thenAnswer((_) async {});

      // 4. Construimos la app.
      await tester.pumpWidget(
        RepositoryProvider<AuthRepository>.value(
          value: mockAuthRepository,
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 6. Verificamos que se muestra el Dashboard.
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('Muestra LoginScreen cuando el usuario está autenticado PERO NO es admin',
        (WidgetTester tester) async {
      // 3. Comportamiento del mock:
      // - Devuelve un stream con un usuario normal.
      // - Cuando se llame a `isAdmin` con el ID de este usuario, devuelve `false`.
      // - Cuando se llame a `logOut`, no hace nada.
      when(() => mockAuthRepository.user).thenAnswer((_) => Stream.value(mockUser));
      when(() => mockAuthRepository.isAdmin(userId: mockUser.id)).thenAnswer((_) async => false);
      when(() => mockAuthRepository.logOut()).thenAnswer((_) async {});

      // 4. Construimos la app.
      await tester.pumpWidget(
        RepositoryProvider<AuthRepository>.value(
          value: mockAuthRepository,
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 6. Verificamos que se muestra la LoginScreen (porque el AuthBloc debería forzar un logout).
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
      // Opcional: verificar que el método logOut fue llamado.
      verify(() => mockAuthRepository.logOut()).called(1);
    });
  });
}