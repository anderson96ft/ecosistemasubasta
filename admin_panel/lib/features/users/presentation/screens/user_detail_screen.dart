// lib/features/users/presentation/screens/user_detail_screen.dart

import 'package:admin_panel/core/models/incident_model.dart';
import 'package:admin_panel/core/models/user_details_model.dart';
import 'package:admin_panel/core/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// --- Estado y Cubit ---
class UserDetailState {
  final UserDetails? userDetails;
  final List<Incident> incidents;
  final bool isLoading;
  final String? error;

  UserDetailState({
    this.userDetails,
    this.incidents = const [],
    this.isLoading = true,
    this.error,
  });
}

class UserDetailCubit extends Cubit<UserDetailState> {
  final AuthRepository _authRepository;
  final String userId;
  UserDetailCubit(this._authRepository, this.userId) : super(UserDetailState()) {
    loadData(); // Llama a loadData desde el constructor
  }

  Future<void> loadData() async {
    try {
      emit(UserDetailState(isLoading: true));
      // Usamos Future.wait para cargar ambos datos en paralelo
      final results = await Future.wait([
        _authRepository.getUserDetails(userId),
        _authRepository.getIncidentsForUser(userId),
      ]);
      
      final userDetails = results[0] as UserDetails;
      final incidents = results[1] as List<Incident>;
      
      emit(UserDetailState(userDetails: userDetails, incidents: incidents, isLoading: false));
    } catch (e) {
      emit(UserDetailState(error: e.toString(), isLoading: false));
    }
  }

  Future<void> banUser() async {
    await _authRepository.banUser(userId);
    // Podríamos recargar los datos, pero lo más probable es que la UI
    // simplemente cierre esta pantalla o muestre un estado de "Baneado".
  }
}

// --- La Pantalla ---
class UserDetailScreen extends StatelessWidget {
  final String userId;
  final String userEmail;
  const UserDetailScreen({super.key, required this.userId, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserDetailCubit(context.read<AuthRepository>(), userId),
      child: Scaffold(
        appBar: AppBar(
          title: Text(userEmail),
        ),
        body: BlocBuilder<UserDetailCubit, UserDetailState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(child: Text('Error: ${state.error}'));
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(title: Text('Email: ${state.userDetails?.email}')),
                ListTile(title: Text('Teléfono: ${state.userDetails?.phone}')),
                // Aquí podrías mostrar el estado 'active'/'banned'
                const Divider(),
                const Text('Historial de Incidentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (state.incidents.isEmpty)
                  const Text('Este usuario no tiene incidentes.'),
                ...state.incidents.map((incident) => Card(
                      child: ListTile(
                        title: Text('Producto: ${incident.productModel}'),
                        subtitle: Text('Motivo: ${incident.reason}\nReportado: ${DateFormat.yMd().add_jm().format(incident.reportedAt.toDate())}'),
                      ),
                    )),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<UserDetailCubit>().banUser();
                    // Mostrar feedback al admin
                  },
                  icon: const Icon(Icons.block),
                  label: const Text('Banear Usuario'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}