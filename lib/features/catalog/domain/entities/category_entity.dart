class CategoryEntity {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
  });

  bool get isMainCategory => parentId == null;
}
