// lib/features/purchases/bloc/purchases_event.dart
import 'package:equatable/equatable.dart';

abstract class PurchasesEvent extends Equatable {
  const PurchasesEvent();
  @override
  List<Object> get props => [];
}

class PurchasesSubscriptionRequested extends PurchasesEvent {}

class PurchasesDataUpdated extends PurchasesEvent {
  final List<dynamic> data;
  const PurchasesDataUpdated(this.data);
}