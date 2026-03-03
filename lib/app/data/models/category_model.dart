class CategoryModel {
  final String id;
  final String name;
  final String icon;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
      };

  static List<CategoryModel> get defaultCategories => const [
        CategoryModel(id: 'all', name: 'Semua', icon: '🏪'),
        CategoryModel(id: 'food', name: 'Makanan', icon: '🍔'),
        CategoryModel(id: 'drink', name: 'Minuman', icon: '☕'),
        CategoryModel(id: 'snack', name: 'Snack', icon: '🍿'),
        CategoryModel(id: 'other', name: 'Lainnya', icon: '📦'),
      ];
}
