import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the active tab index and transition state for Liquid Flow navigation.
/// 0: Library
/// 1: Folders
/// 2: Player
final navigationProvider = NotifierProvider<NavigationNotifier, NavigationState>(NavigationNotifier.new);

class NavigationState {
  final int currentIndex;
  final int previousIndex;
  final Offset? tapPosition; 
  final bool isTransitioning;

  NavigationState({
    required this.currentIndex,
    required this.previousIndex,
    this.tapPosition,
    this.isTransitioning = false,
  });

  NavigationState copyWith({
    int? currentIndex,
    int? previousIndex,
    Offset? tapPosition,
    bool? isTransitioning,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      previousIndex: previousIndex ?? this.previousIndex,
      tapPosition: tapPosition ?? this.tapPosition,
      isTransitioning: isTransitioning ?? this.isTransitioning,
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() => NavigationState(currentIndex: 2, previousIndex: 2);

  void setIndex(int index, {Offset? tapPosition}) {
    if (state.currentIndex == index) return;
    
    state = state.copyWith(
      previousIndex: state.currentIndex,
      currentIndex: index,
      tapPosition: tapPosition,
      isTransitioning: true,
    );
  }

  void endTransition() {
    state = state.copyWith(isTransitioning: false);
  }
}
