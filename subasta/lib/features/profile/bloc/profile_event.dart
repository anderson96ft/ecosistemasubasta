// lib/features/profile/bloc/profile_event.dart

import 'package:equatable/equatable.dart';
import 'package:subasta/features/profile/bloc/profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object> get props => [];
}

class ProfileSubscriptionRequested extends ProfileEvent {}

class ProfileDataUpdated extends ProfileEvent {
  final Map<String, dynamic> data;
  const ProfileDataUpdated(this.data);
}

enum SortOption { date, name, price }

class SortHistoryRequested extends ProfileEvent {
  final SortOption sortOption;
  const SortHistoryRequested(this.sortOption);

  @override
  List<Object> get props => [sortOption];
}