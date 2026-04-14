import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_collection.dart';

final collectionsProvider = AsyncNotifierProvider<CollectionsNotifier, List<LocalCollection>>(
  CollectionsNotifier.new,
);

class CollectionsNotifier extends AsyncNotifier<List<LocalCollection>> {
  static const String _storageKey = 'famsic_collections';

  @override
  Future<List<LocalCollection>> build() async {
    return _loadFromPrefs();
  }

  Future<List<LocalCollection>> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? collectionsJson = prefs.getString(_storageKey);
    
    if (collectionsJson == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(collectionsJson);
      return decoded.map((item) => LocalCollection.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveToPrefs(List<LocalCollection> collections) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(collections.map((c) => c.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addCollection(LocalCollection collection) async {
    final current = state.value ?? [];
    final updated = [...current, collection];
    state = AsyncValue.data(updated);
    await _saveToPrefs(updated);
  }

  Future<void> removeCollection(String id) async {
    final current = state.value ?? [];
    final updated = current.where((c) => c.id != id).toList();
    state = AsyncValue.data(updated);
    await _saveToPrefs(updated);
  }

  Future<void> updateCollection(LocalCollection updatedColl) async {
    final current = state.value ?? [];
    final updated = current.map((c) => c.id == updatedColl.id ? updatedColl : c).toList();
    state = AsyncValue.data(updated);
    await _saveToPrefs(updated);
  }
}
