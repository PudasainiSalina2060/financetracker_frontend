import 'package:flutter/material.dart';

class CategoryModel {
  final int id;
  final String name;
  final String icon; 
  final String type; 

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

IconData getIcon() {
  switch (icon) {
    // Income Categories
    case 'cash-outline': 
      return Icons.payments_outlined; 
    case 'briefcase-outline': 
      return Icons.work_outline;
    case 'trending-up-outline': 
      return Icons.trending_up;
    case 'gift-outline': 
      return Icons.card_giftcard;
    case 'business-outline': 
      return Icons.location_city;

    // Expense Categories
    case 'fast-food-outline': 
      return Icons.restaurant;
    case 'car-outline': 
      return Icons.directions_car_filled_outlined;
    case 'home-outline': 
      return Icons.home_outlined;
    case 'airplane-outline': 
      return Icons.flight_takeoff;
    case 'flash-outline': 
      return Icons.electric_bolt;
    case 'medical-outline': 
      return Icons.medical_services_outlined;
    case 'cart-outline': 
      return Icons.shopping_cart_outlined;
    case 'book-outline': 
      return Icons.book_outlined;
    case 'shield-checkmark-outline': 
      return Icons.admin_panel_settings_outlined;
    case 'card-outline': 
      return Icons.credit_card_outlined;

    // Default icon
    default: 
      return Icons.help_outline; 
  }
}

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['category_id'],
      name: json['name'],
      icon: json['icon'] ?? 'help-outline',
      type: json['type'],
    );
  }
}