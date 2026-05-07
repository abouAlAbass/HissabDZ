import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hissab_dz/l10n/app_localizations.dart';
import 'package:hissab_dz/core/widgets/app_drawer.dart';
import 'package:hissab_dz/features/articles/presentation/providers/article_providers.dart';

class ArticleListScreen extends ConsumerWidget {
  const ArticleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final articlesAsync = ref.watch(filteredArticlesProvider);
    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.articles),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) => ref.read(articleSearchQueryProvider.notifier).update(value),
              decoration: InputDecoration(
                hintText: l10n.searchArticles,
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: articlesAsync.when(
        data: (articles) {
          if (articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noArticles, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              final isService = article.type == 'service';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isService ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                    child: Icon(isService ? Icons.build_circle : Icons.inventory_2, color: isService ? Colors.orange : Colors.blue),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(article.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Text(
                        currencyFormat.format(article.price),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${article.code != null ? "${article.code} • " : ""}${article.unit} • ${isService ? l10n.service : l10n.physical}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed('edit_article', pathParameters: {'id': article.id.toString()}),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('add_article'),
        tooltip: l10n.addArticle,
        child: const Icon(Icons.add),
      ),
    );
  }
}
