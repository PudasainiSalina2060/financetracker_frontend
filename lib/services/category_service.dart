import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';

class CategoryService {
  final String baseUrl = "http://10.0.2.2:3000";

  Future<List<CategoryModel>> getAllCategories(String token) async {
    final response = await http.get(Uri.parse("$baseUrl/api/categories/all"),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }
}