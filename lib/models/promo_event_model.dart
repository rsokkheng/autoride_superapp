class PromoEventModel {
  final int     id;
  final String  title;
  final String  body;
  final String? imageUrl;
  final String  createdAt;

  const PromoEventModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.createdAt,
  });

  factory PromoEventModel.fromJson(Map<String, dynamic> json) => PromoEventModel(
    id:        json['id'] as int? ?? 0,
    title:     json['title']?.toString() ?? '',
    body:      json['body']?.toString() ?? '',
    imageUrl:  json['image_url']?.toString(),
    createdAt: json['created_at']?.toString() ?? '',
  );
}
