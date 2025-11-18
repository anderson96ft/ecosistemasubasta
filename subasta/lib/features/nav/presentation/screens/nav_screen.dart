// lib/features/nav/presentation/screens/nav_screen.dart

import 'package:subasta/core/repositories/product_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:subasta/features/auth/bloc/auth_state.dart';
import 'package:subasta/features/auth/presentation/screens/login_screen.dart';
import 'package:subasta/features/chat_list/presentation/screens/chat_list_screen.dart';
import 'package:subasta/features/home/presentation/screens/home_screen.dart';
import 'package:subasta/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavScreen extends StatefulWidget {
  final int initialIndex;
  const NavScreen({super.key, this.initialIndex = 0});
  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Usa el índice inicial que se pasó al widget
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    final isAuthenticated =
        context.read<AuthBloc>().state.status == AuthStatus.authenticated;
        
    // Pestaña "Inicio" (índice 0) siempre es accesible
    if (index == 0) {
       setState(() {
         _selectedIndex = index;
       });
       return;
    }
    
    // Pestañas protegidas (índice > 0)
    if (!isAuthenticated) {
      // Si no está autenticado, redirige a la pantalla de login
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      // Si está autenticado, simplemente cambia de pestaña
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa el estado de autenticación para construir la lista de pantallas
    final isAuthenticated =
        context.watch<AuthBloc>().state.status == AuthStatus.authenticated;

    // --- LISTA DE PANTALLAS SIMPLIFICADA ---
    final List<Widget> screens = [
      const HomeScreen(), // Índice 0
      isAuthenticated
          ? const ChatListScreen() 
          : const _LoginRequiredScreen(title: 'Mensajes'), // Índice 1
      isAuthenticated
          ? const ProfileScreen()
          : const _LoginRequiredScreen(title: 'Mi Actividad'), // Índice 2
    ];

    return Scaffold(
      // IndexedStack preserva el estado de las pantallas al cambiar de pestaña
      body: IndexedStack(index: _selectedIndex, children: screens),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Muestra todas las etiquetas
        
        // --- ITEMS DE NAVEGACIÓN SIMPLIFICADOS ---
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio', // Índice 0
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Mensajes', // Índice 1
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Mi Actividad', // Índice 2
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Llama a nuestra lógica al tocar una pestaña
      ),
      
      // Muestra el botón flotante de depuración solo en la pestaña Inicio y en modo debug
      floatingActionButton:
          _selectedIndex == 0 && kDebugMode
              ? FloatingActionButton(
                  child: const Icon(Icons.bug_report),
                  tooltip: 'Panel de Depuración',
                  onPressed: () => _showDebugPanel(context),
                )
              : null,
    );
  }
  
  // --- Método para mostrar el panel de depuración (sembrador de datos) ---
  void _showDebugPanel(BuildContext context) {
     final productRepo = context.read<ProductRepository>();
     final userId = context.read<AuthBloc>().state.user.id;
     if (userId.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Inicia sesión para usar el panel de depuración.'),
           backgroundColor: Colors.orange,
         ),
       );
       return;
     }
     
     // Muestra las opciones del seeder
     showModalBottomSheet(
       context: context,
       builder: (_) {
         return Wrap(
           children: <Widget>[
             const ListTile(
               title: Text(
                 'Simular Escenarios',
                 style: TextStyle(fontWeight: FontWeight.bold),
               ),
             ),
             ListTile(
               leading: const Icon(Icons.refresh),
               title: const Text('Estado Limpio (Productos Activos)'),
               onTap: () {
                 productRepo.seedDatabase(
                   scenario: SeederScenario.clean,
                   currentUserId: userId,
                   otherUserId: 'otro_usuario_test',
                 );
                 Navigator.pop(context);
               },
             ),
             ListTile(
               leading: const Icon(Icons.trending_up),
               title: const Text('Voy Ganando una Subasta'),
               onTap: () {
                 productRepo.seedDatabase(
                   scenario: SeederScenario.userIsWinning,
                   currentUserId: userId,
                   otherUserId: 'otro_usuario_test',
                 );
                 Navigator.pop(context);
               },
             ),
             ListTile(
               leading: const Icon(Icons.trending_down),
               title: const Text('Voy Perdiendo una Subasta'),
               onTap: () {
                 productRepo.seedDatabase(
                   scenario: SeederScenario.userIsLosing,
                   currentUserId: userId,
                   otherUserId: 'otro_usuario_test',
                 );
                 Navigator.pop(context);
               },
             ),
             ListTile(
               leading: const Icon(Icons.emoji_events),
               title: const Text('He Ganado una Subasta'),
               onTap: () {
                 productRepo.seedDatabase(
                   scenario: SeederScenario.userHasWon,
                   currentUserId: userId,
                   otherUserId: 'otro_usuario_test',
                 );
                 Navigator.pop(context);
               },
             ),
             ListTile(
               leading: const Icon(Icons.shopping_cart),
               title: const Text('He Comprado un Artículo'),
               onTap: () {
                 productRepo.seedDatabase(
                   scenario: SeederScenario.userHasPurchased,
                   currentUserId: userId,
                   otherUserId: 'otro_usuario_test',
                 );
                 Navigator.pop(context);
               },
             ),
           ],
         );
       },
     );
  }
}


// Widget auxiliar simple para mostrar a los invitados en las pestañas protegidas.
class _LoginRequiredScreen extends StatelessWidget {
  final String title;
  const _LoginRequiredScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                'Inicia sesión para acceder a esta sección',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Registrarte te permite pujar, comprar y gestionar tu actividad.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    // Redirige a LoginScreen
                    builder: (_) => const LoginScreen(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('INICIAR SESIÓN O REGISTRARSE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}