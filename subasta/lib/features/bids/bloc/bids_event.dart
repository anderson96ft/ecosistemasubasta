// lib/features/bids/bloc/bids_event.dart

import 'package:equatable/equatable.dart';

abstract class BidsEvent extends Equatable {
  const BidsEvent();
  @override
  List<Object> get props => [];
}

class BidsSubscriptionRequested extends BidsEvent {}

// === EVENTO CORREGIDO (SIN GUION BAJO) ===
// Evento interno para actualizar la UI con los nuevos datos del stream.
class BidsDataUpdated extends BidsEvent {
  final Map<String, dynamic> data;
  const BidsDataUpdated(this.data);
}