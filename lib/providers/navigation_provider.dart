import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the active tab index for the MainLayout.
/// 0: Library
/// 1: Folders
/// 2: Player
final navigationProvider = NotifierProvider<NavigationNotifier, int>(NavigationNotifier.new);

class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 2;

  void setIndex(int index) => state = index;
}
