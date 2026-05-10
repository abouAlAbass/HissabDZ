import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hissab_dz/features/quotes/data/repositories/quote_repository.dart';
import 'package:hissab_dz/features/quotes/domain/entities/quote_status.dart';
import 'package:hissab_dz/features/quotes/presentation/providers/quote_providers.dart';
import 'package:hissab_dz/features/quotes/presentation/widgets/quote_status_label.dart';
import 'package:hissab_dz/l10n/app_localizations.dart';

class QuoteDetailsScreen extends ConsumerWidget {
  final int quoteId;

  const QuoteDetailsScreen({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final quoteAsync = ref.watch(quoteByIdProvider(quoteId));
    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quoteDetails),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.pushNamed(
              'edit_quote',
              pathParameters: {'id': quoteId.toString()},
            ),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _confirmDeleteQuote(context, ref, l10n),
          ),
        ],
      ),
      body: quoteAsync.when(
        data: (quote) {
          if (quote == null) return Center(child: Text(l10n.noData));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quote.quoteNumber,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  QuoteStatusChip(status: quote.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.clientName}: ${quote.client?.name ?? l10n.unknownClient}',
              ),
              if (quote.projectName != null)
                Text('${l10n.project}: ${quote.projectName}'),
              Text('${l10n.issueDate}: ${dateFormat.format(quote.issueDate)}'),
              if (quote.validUntil != null)
                Text(
                  '${l10n.validUntil}: ${dateFormat.format(quote.validUntil!)}',
                ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: quote.items
                      .map(
                        (item) => ListTile(
                          title: Text(item.description),
                          subtitle: Text(
                            '${item.quantity} x ${currencyFormat.format(item.unitPrice)}',
                          ),
                          trailing: Text(
                            currencyFormat.format(item.amount),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              _amountRow(l10n.subtotal, currencyFormat.format(quote.subtotal)),
              _amountRow(
                l10n.totalTax,
                currencyFormat.format(quote.subtotal * quote.taxRate / 100),
              ),
              _amountRow(
                l10n.discount,
                currencyFormat.format(quote.discountAmount),
              ),
              const Divider(),
              _amountRow(
                l10n.total,
                currencyFormat.format(quote.total),
                isTotal: true,
              ),
              if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.notes,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(quote.notes!),
              ],
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.draw_outlined),
                  title: Text(l10n.goodForApproval),
                  subtitle: Text(
                    quote.approvalName?.isNotEmpty == true
                        ? quote.approvalName!
                        : l10n.notProvided,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: quote.status == QuoteStatus.converted
                        ? null
                        : () => _convert(context, ref, l10n),
                    icon: const Icon(Icons.receipt_long),
                    label: Text(l10n.convertToInvoice),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _setStatus(
                      ref,
                      QuoteStatus.sent,
                      approvalName: quote.approvalName,
                    ),
                    icon: const Icon(Icons.send_outlined),
                    label: Text(l10n.sent),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _accept(context, ref, l10n),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(l10n.accepted),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _setStatus(
                      ref,
                      QuoteStatus.rejected,
                      approvalName: quote.approvalName,
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(l10n.rejected),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${l10n.error}: $e')),
      ),
    );
  }

  Widget _amountRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              fontSize: isTotal ? 18 : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.approvalSignature),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.clientName,
            helperText: l10n.goodForApproval,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await _setStatus(ref, QuoteStatus.accepted, approvalName: name);
  }

  Future<void> _setStatus(
    WidgetRef ref,
    QuoteStatus status, {
    String? approvalName,
  }) async {
    await ref
        .read(quoteRepositoryProvider)
        .updateQuoteStatus(quoteId, status, approvalName: approvalName);
    ref.invalidate(quoteByIdProvider(quoteId));
    ref.invalidate(quotesListProvider);
  }

  Future<void> _convert(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final invoiceId = await ref
        .read(quoteRepositoryProvider)
        .convertToInvoice(quoteId);
    ref.invalidate(quoteByIdProvider(quoteId));
    ref.invalidate(quotesListProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.quoteConverted)));
    context.pushNamed(
      'invoice_details',
      pathParameters: {'id': invoiceId.toString()},
    );
  }

  Future<void> _confirmDeleteQuote(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteQuoteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(quoteRepositoryProvider).deleteQuote(quoteId);
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.quoteDeleted)),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
