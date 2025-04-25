import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/age_prediction.dart';

final generatedAgesProvider =
    StateNotifierProvider<GeneratedAgesNotifier, List<GeneratedAge>>((ref) {
  return GeneratedAgesNotifier();
});

class GeneratedAgesNotifier extends StateNotifier<List<GeneratedAge>> {
  GeneratedAgesNotifier() : super([]) {
    loadSavedAges();
  }

  Future<void> loadSavedAges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAges = prefs.getStringList('generated_ages') ?? [];

      final loadedAges = savedAges
          .map((ageJson) {
            try {
              return GeneratedAge.fromJson(jsonDecode(ageJson));
            } catch (e) {
              print('Error parsing age: $e');
              return null;
            }
          })
          .whereType<GeneratedAge>()
          .toList();

      loadedAges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = loadedAges;
    } catch (e) {
      print('Error loading saved ages: $e');
      state = [];
    }
  }

  Future<void> addAgedImage(
    String imageUrl,
    String originalImageUrl,
    int targetAge,
  ) async {
    final newAge = GeneratedAge(
      id: const Uuid().v4(),
      imageUrl: imageUrl,
      originalImageUrl: originalImageUrl,
      targetAge: targetAge,
      createdAt: DateTime.now(),
    );

    state = [...state, newAge];
    await _saveAges();
  }

  Future<void> deleteAgedImage(String id) async {
    state = state.where((age) => age.id != id).toList();
    await _saveAges();
  }

  Future<void> _saveAges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final agesJson = state.map((age) => jsonEncode(age.toJson())).toList();
      await prefs.setStringList('generated_ages', agesJson);
    } catch (e) {
      print('Error saving ages: $e');
    }
  }
}
