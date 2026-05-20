enum FoodCategory { appetizer, main_course, dessert, beverage, snack, other }

extension FoodCategoryExt on FoodCategory {
  String get label {
    switch (this) {
      case FoodCategory.appetizer:   return 'Appetizer';
      case FoodCategory.main_course: return 'Main Course';
      case FoodCategory.dessert:     return 'Dessert';
      case FoodCategory.beverage:    return 'Beverage';
      case FoodCategory.snack:       return 'Snack';
      case FoodCategory.other:       return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case FoodCategory.appetizer:   return '🥗';
      case FoodCategory.main_course: return '🍽️';
      case FoodCategory.dessert:     return '🍰';
      case FoodCategory.beverage:    return '🥤';
      case FoodCategory.snack:       return '🍿';
      case FoodCategory.other:       return '🍴';
    }
  }

  String get value => name;
}

class FoodItem {
  final String id;
  final String userId;
  final String? eventId;
  final String name;
  final String? description;
  final FoodCategory category;
  final double price;
  final int quantity;
  final int quantityServed;
  final String? imageUrl;
  final bool isVegetarian;
  final bool isAvailable;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FoodItem({
    required this.id,
    required this.userId,
    this.eventId,
    required this.name,
    this.description,
    required this.category,
    this.price = 0.0,
    this.quantity = 1,
    this.quantityServed = 0,
    this.imageUrl,
    this.isVegetarian = false,
    this.isAvailable = true,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Remaining quantity available (quantity - quantityServed).
  int get remaining => (quantity - quantityServed).clamp(0, quantity);

  /// Percentage served (0–100). Returns null if quantity = 0.
  double? get servedPercent =>
      quantity > 0 ? (quantityServed / quantity * 100).clamp(0, 100) : null;

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      eventId: map['event_id'],
      name: map['name'] ?? '',
      description: map['description'],
      category: FoodCategory.values.firstWhere(
        (e) => e.value == map['category'],
        orElse: () => FoodCategory.other,
      ),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 1,
      quantityServed: map['quantity_served'] ?? 0,
      imageUrl: map['image_url'],
      isVegetarian: map['is_vegetarian'] ?? false,
      isAvailable: map['is_available'] ?? true,
      notes: map['notes'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'name': name,
      'description': description,
      'category': category.value,
      'price': price,
      'quantity': quantity,
      // FIX: quantity_served intentionally NOT included here so updates
      // don't accidentally reset the served count. Use updateQuantityServed()
      // from FoodService for that purpose specifically.
      'image_url': imageUrl,
      'is_vegetarian': isVegetarian,
      'is_available': isAvailable,
      'notes': notes,
    };
  }
}