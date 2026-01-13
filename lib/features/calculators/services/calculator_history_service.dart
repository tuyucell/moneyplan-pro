import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// --- Model ---
class CalculatorHistoryItem {
  final String id;
  final String title;
  final String date;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> results;
  final String type; // 'real_estate', 'investment', etc.

  CalculatorHistoryItem({
    required this.id,
    required this.title,
    required this.date,
    required this.inputs,
    required this.results,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'inputs': inputs,
      'results': results,
      'type': type,
    };
  }

  factory CalculatorHistoryItem.fromJson(Map<String, dynamic> json) {
    return CalculatorHistoryItem(
      id: json['id'],
      title: json['title'],
      date: json['date'],
      inputs: json['inputs'],
      results: json['results'],
      type: json['type'],
    );
  }
}

// --- Service ---
class CalculatorHistoryService {
  static const String _storageKey = 'calculator_history';
  
  // Singleton pattern
  static final CalculatorHistoryService _instance = CalculatorHistoryService._internal();
  factory CalculatorHistoryService() => _instance;
  CalculatorHistoryService._internal();

  Future<List<CalculatorHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => CalculatorHistoryItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveResult(CalculatorHistoryItem item) async {
    final canSave = await checkSaveLimit();
    if (!canSave) {
      throw Exception('Kayıt limitine ulaşıldı. Premium\'a geçerek sınırsız kayıt yapabilirsiniz.');
    }

    final prefs = await SharedPreferences.getInstance();
    var currentHistory = await getHistory();
    
    // Yeni kaydı en başa ekle
    currentHistory.insert(0, item);
    
    await prefs.setString(_storageKey, jsonEncode(currentHistory.map((e) => e.toJson()).toList()));
  }

  Future<void> deleteItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    var currentHistory = await getHistory();
    
    currentHistory.removeWhere((item) => item.id == id);
    
    await prefs.setString(_storageKey, jsonEncode(currentHistory.map((e) => e.toJson()).toList()));
  }

  // LIMIT KONTROL MEKANİZMASI
  // İleride buraya user tier kontrolü eklenecek
  Future<bool> checkSaveLimit() async {
    // Örnek Logic:
    // final userTier = ...get from auth...
    // if (userTier == 'free') {
    //    final history = await getHistory();
    //    return history.length < 5;
    // }
    
    return true; // Şimdilik sınırsız
  }
}
