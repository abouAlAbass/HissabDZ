import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_app/core/database/database.dart';
import 'package:invoice_app/core/database/database_provider.dart';
import 'package:invoice_app/features/articles/domain/entities/article.dart';

abstract class ArticleRepository {
  Stream<List<Article>> watchArticles();
  Future<int> addArticle(Article article);
  Future<void> updateArticle(Article article);
  Future<void> deleteArticle(int id);
}

class ArticleRepositoryImpl implements ArticleRepository {
  final AppDatabase _db;

  ArticleRepositoryImpl(this._db);

  @override
  Stream<List<Article>> watchArticles() {
    return _db.select(_db.articles).watch().map((rows) {
      return rows.map((data) => Article(
        id: data.id,
        name: data.name,
        code: data.code,
        price: data.price,
        unit: data.unit,
        type: data.type,
        createdAt: data.createdAt,
      )).toList();
    });
  }

  @override
  Future<int> addArticle(Article article) {
    return _db.into(_db.articles).insert(
      ArticlesCompanion.insert(
        name: article.name,
        code: Value(article.code),
        price: Value(article.price),
        unit: article.unit,
        type: Value(article.type),
      ),
    );
  }

  @override
  Future<void> updateArticle(Article article) {
    return (_db.update(_db.articles)..where((t) => t.id.equals(article.id!))).write(
      ArticlesCompanion(
        name: Value(article.name),
        code: Value(article.code),
        price: Value(article.price),
        unit: Value(article.unit),
        type: Value(article.type),
      ),
    );
  }

  @override
  Future<void> deleteArticle(int id) {
    return (_db.delete(_db.articles)..where((t) => t.id.equals(id))).go();
  }
}

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ArticleRepositoryImpl(db);
});
