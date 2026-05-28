class CarPart {
  final String id;
  final String className;
  final String? description;
  final double? averagePrice;
  final String? compatibilityNotes;

  CarPart({
    required this.id,
    required this.className,
    this.description,
    this.averagePrice,
    this.compatibilityNotes,
  });

  factory CarPart.fromJson(Map<String, dynamic> json) {
    return CarPart(
      id: json['id'],
      className: json['class_name'],
      description: json['description'],
      averagePrice: json['average_price'] != null
          ? double.tryParse(json['average_price'].toString())
          : null,
      compatibilityNotes: json['compatibility_notes'],
    );
  }
}
