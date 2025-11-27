class BookModel {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final double price;
  final String description;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.price,
    required this.description,
  });

  /// Create a BookModel from Firestore map
  factory BookModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return BookModel(
      id: id ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      imageUrl: map['imageUrl'] ?? '', // Always default to empty string if missing
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
    );
  }

  /// Convert BookModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'price': price,
      'description': description,
    };
  }

  /// Helper: Check if imageUrl is a valid network image
  bool get hasValidImage =>
      imageUrl.isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

  /// Create a copy of the BookModel
  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? imageUrl,
    double? price,
    String? description,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      description: description ?? this.description,
    );
  }
}
