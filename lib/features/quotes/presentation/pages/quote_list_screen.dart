import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hissab_dz/core/widgets/app_drawer.dart';
import 'package:hissab_dz/features/quotes/presentation/providers/quote_providers.dart';
import 'package:hissab_dz/features/quotes/presentation/widgets/quote_status_label.dart';
import 'package:hissab_dz/l10n/app_localizations.dart';

class QuoteListScreen extends ConsumerWidget {
  const QuoteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final quotesAsync = ref.watch(quotesListProvider);
    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);

    return Scaffold(
      drawer: MediaQuery.sizeOf(context).width >= 1100
          ? null
          : const AppDrawer(),
      appBar: AppBar(title: Text(l10n.quotes)),
      body: quotesAsync.when(
        data: (quotes) {
          if (quotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.request_quote_outlined,
                    size: 72,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noQuotes,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.pushNamed('create_quote'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createQuote),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 112),
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              final quote = quotes[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(quote.quoteNumber.split('-').last),
                  ),
                  title: Text(
                    quote.client?.name ?? l10n.unknownClient,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${quote.quoteNumber} - ${dateFormat.format(quote.issueDate)}',
                      ),
                      if (quote.projectName != null)
                        Text('${l10n.project}: ${quote.projectName}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(quote.total),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      QuoteStatusChip(status: quote.status),
                    ],
                  ),
                  onTap: () => context.pushNamed(
                    'quote_details',
                    pathParameters: {'id': quote.id.toString()},
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${l10n.error}: $e')),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          onPressed: () => context.pushNamed('create_quote'),
          tooltip: l10n.createQuote,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
