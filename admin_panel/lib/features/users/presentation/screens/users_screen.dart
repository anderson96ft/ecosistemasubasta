// lib/features/users/presentation/screens/users_screen.dart

import 'package:admin_panel/core/models/user_model.dart';
import 'package:admin_panel/core/repositories/auth_repository.dart';
// --- 1. IMPORTA LA PANTALLA DE CHAT ---
import 'package:admin_panel/features/chat/presentation/screens/chat_detail_screen.dart';
// --- 2. IMPORTA EL AUTHBLOC (para el ID del admin) ---
import 'package:admin_panel/features/auth/bloc/auth_bloc.dart';
import 'package:admin_panel/features/users/presentation/screens/user_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- (El UsersState y UsersCubit se mantienen exactamente igual que antes) ---
class UsersState {
  final List<UserModel> users;
  final bool isLoading;
  final String? error;
  UsersState({this.users = const [], this.isLoading = true, this.error});
}

class UsersCubit extends Cubit<UsersState> {
  final AuthRepository _authRepository;
  UsersCubit(this._authRepository) : super(UsersState());

  Future<void> loadUsers() async {
    try {
      emit(UsersState(isLoading: true));
      final users = await _authRepository.listAllUsers(); // Llamada correcta
      emit(UsersState(users: users, isLoading: false));
    } catch (e) {
      emit(UsersState(error: e.toString(), isLoading: false));
    }
  }
}
// --- (Fin de UsersState y UsersCubit) ---


// --- La Pantalla ---
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 3. OBTÉN EL ID DEL ADMIN ACTUAL ---
    // Lo usaremos para crear la conversación 1-a-1
    final adminId = context.read<AuthBloc>().state.user.id;

    return BlocProvider(
      create:
          (context) => UsersCubit(context.read<AuthRepository>())..loadUsers(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Gestión de Usuarios')),
        body: BlocBuilder<UsersCubit, UsersState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(child: Text('Error: ${state.error}'));
            }
            if (state.users.isEmpty) {
              return const Center(child: Text('No hay usuarios registrados.'));
            }

            return ListView.builder(
              itemCount: state.users.length,
              itemBuilder: (context, index) {
                final user = state.users[index];
                
                // --- 4. GENERA EL ID DE CONVERSACIÓN PREDECIBLE ---
                // Se ordena alfabéticamente para asegurar que sea el mismo ID
                // tanto para el admin como para el usuario.
                final participants = [adminId, user.id]..sort();
                final conversationId = participants.join('_'); // Ej: "adminUID_userUID"

                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(user.email ?? 'Sin email'),
                  subtitle: Text('UID: ${user.id}'),
                  
                  // --- 5. MODIFICA EL 'trailing' PARA AÑADIR EL BOTÓN DE CHAT ---
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Para que la Row no ocupe todo el ancho
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat_outlined),
                        tooltip: 'Iniciar chat con este usuario',
                        color: Theme.of(context).primaryColor,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                // El ID de conversación único y predecible
                                conversationId: conversationId,
                                // El "otro" usuario es el de esta fila
                                otherUserId: user.id, 
                                // Pasamos datos genéricos para este chat "no-producto"
                                productId: 'soporte_${user.id}', // ID genérico de producto
                                productModel: 'Soporte General', // Título para el chat
                                productImage: null, // O un logo de soporte si tienes
                              ),
                            ),
                          );
                        },
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), // El botón de detalles
                    ],
                  ),
                  // --- FIN DE LA MODIFICACIÓN ---

                  onTap: () {
                    // Mantenemos la navegación a la pantalla de detalles
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UserDetailScreen(
                          userId: user.id,
                          userEmail: user.email ?? '',
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}