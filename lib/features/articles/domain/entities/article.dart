import 'package:freezed_annotation/freezed_annotation.dart';

part 'article.freezed.dart';
part 'article.g.dart';

@freezed
class Article with _$Article {
  const factory Article({
    int? id,
    required String name,
    String? code,
    required double price,
    required String unit, // kg, m2, m3, pieces
    @Default('physical') String type, // physical, service
    @Default('materials') String category,
    @Default(0.0) double taxRate,
    @Default(0.0) double marginRate,
    DateTime? createdAt,
  }) = _Article;

  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);
}
