import 'package:admin_panel/core/repositories/auth_repository.dart';
import 'package:admin_panel/core/repositories/chat_repository.dart';
import 'package:admin_panel/core/repositories/product_repository.dart';
import 'package:admin_panel/core/repositories/storage_repository.dart';
import 'package:admin_panel/features/auth/bloc/auth_bloc.dart';
import 'package:admin_panel/presentation/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:admin_panel/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Proveemos todos los repositorios a la aplicación.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => ProductRepository()),
        RepositoryProvider(create: (context) => ChatRepository()),
        RepositoryProvider(create: (context) => StorageRepository()),
      ],
      // 2. Proveemos el AuthBloc, que depende de AuthRepository.
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
        ),
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. El router ahora se crea aquí, con acceso al AuthBloc.
    final router = AppRouter(context.read<AuthBloc>()).router;
    return MaterialApp.router(
      routerConfig: router,
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}