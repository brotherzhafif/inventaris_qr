class Item {
  final int? id;
  final String name;
  final String barcode;
  final String? imagePath;
  final int categoryId;
  final String location;
  final DateTime dateAdded;
  final int currentStock;
  final String? description;

  Item({
    this.id,
    required this.name,
    required this.barcode,
    this.imagePath,
    required this.categoryId,
    required this.location,
    required this.dateAdded,
    required this.currentStock,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'image_path': imagePath,
      'category_id': categoryId,
      'location': location,
      'date_added': dateAdded.toIso8601String(),
      'current_stock': currentStock,
      'description': description,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      imagePath: map['image_path'],
      categoryId: map['category_id']?.toInt() ?? 0,
      location: map['location'] ?? '',
      dateAdded: DateTime.parse(map['date_added']),
      currentStock: map['current_stock']?.toInt() ?? 0,
      description: map['description'],
    );
  }

  Item copyWith({
    int? id,
    String? name,
    String? barcode,
    String? imagePath,
    int? categoryId,
    String? location,
    DateTime? dateAdded,
    int? currentStock,
    String? description,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
      categoryId: categoryId ?? this.categoryId,
      location: location ?? this.location,
      dateAdded: dateAdded ?? this.dateAdded,
      currentStock: currentStock ?? this.currentStock,
      description: description ?? this.description,
    );
  }

  bool get isLowStock => currentStock <= 5;
  bool get isOutOfStock => currentStock <= 0;
}
