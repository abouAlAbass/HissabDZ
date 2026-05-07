// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArticleImpl _$$ArticleImplFromJson(Map<String, dynamic> json) =>
    _$ArticleImpl(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      code: json['code'] as String?,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      type: json['type'] as String? ?? 'physical',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ArticleImplToJson(_$ArticleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'price': instance.price,
      'unit': instance.unit,
      'type': instance.type,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
