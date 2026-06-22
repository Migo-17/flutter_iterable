/// A single item involved in a purchase or cart update.
class IterableCommerceItem {
  IterableCommerceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.sku,
    this.description,
    this.url,
    this.imageUrl,
    this.categories,
    this.dataFields,
  });

  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? sku;
  final String? description;
  final String? url;
  final String? imageUrl;
  final List<String>? categories;
  final Map<String, dynamic>? dataFields;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      if (sku != null) 'sku': sku,
      if (description != null) 'description': description,
      if (url != null) 'url': url,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (categories != null) 'categories': categories,
      if (dataFields != null) 'dataFields': dataFields,
    };
  }

  factory IterableCommerceItem.fromMap(Map<String, dynamic> map) {
    return IterableCommerceItem(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(),
      sku: map['sku'] as String?,
      description: map['description'] as String?,
      url: map['url'] as String?,
      imageUrl: map['imageUrl'] as String?,
      categories: (map['categories'] as List?)?.cast<String>(),
      dataFields: (map['dataFields'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
