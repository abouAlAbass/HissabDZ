import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../../../invoices/presentation/providers/invoice_providers.dart';
import '../providers/payment_providers.dart';

class PaymentListScreen extends ConsumerWidget {
  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final paymentsAsync = ref.watch(paymentsListProvider);
    final invoicesAsync = ref.watch(invoicesListProvider());
    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.payments)),
      drawer: MediaQuery.sizeOf(context).width >= 1100
          ? null
          : const AppDrawer(),
      body: paymentsAsync.when(
        data: (payments) => invoicesAsync.when(
          data: (invoices) {
            final paidByInvoice = <int, double>{};
            for (final payment in payments) {
              paidByInvoice[payment.invoiceId] =
                  (paidByInvoice[payment.invoiceId] ?? 0) + payment.amount;
            }
            final unpaidInvoices = invoices.where((invoice) {
              final remaining =
                  invoice.total - (paidByInvoice[invoice.id] ?? 0);
              return invoice.status != InvoiceStatus.paid && remaining > 0;
            }).toList();

            if (payments.isEmpty && unpaidInvoices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noPayments,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: [
                Text(
                  l10n.unpaidInvoices,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (unpaidInvoices.isEmpty)
                  Card(child: ListTile(title: Text(l10n.noInvoices)))
                else
                  ...unpaidInvoices.map((invoice) {
                    final paid = paidByInvoice[invoice.id] ?? 0;
                    final remaining = invoice.total - paid;
                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.pending_actions,
                          color: Colors.orange,
                        ),
                        title: Text(
                          invoice.client?.name ?? l10n.unknownClient,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(invoice.invoiceNumber),
                            Text(
                              '${l10n.paidAmount}: ${currencyFormat.format(paid)}',
                            ),
                            Text(
                              '${l10n.lastReminder}: ${invoice.lastReminderAt == null ? l10n.notProvided : DateFormat.yMMMd(l10n.localeName).format(invoice.lastReminderAt!)}',
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(remaining),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(l10n.remainingToPay),
                          ],
                        ),
                        onTap: () => context.pushNamed(
                          'invoice_details',
                          pathParameters: {'id': invoice.id.toString()},
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                if (unpaidInvoices.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: unpaidInvoices.take(3).map((invoice) {
                      return OutlinedButton.icon(
                        onPressed: () => _sendReminder(context, ref, invoice),
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: Text(
                          '${l10n.sendReminder} ${invoice.invoiceNumber}',
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                Text(
                  l10n.history,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (payments.isEmpty)
                  Card(child: ListTile(title: Text(l10n.noPayments)))
                else
                  ...payments.map((payment) {
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: const Icon(
                            Icons.call_received,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          payment.client?.name ?? l10n.unknownClient,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.invoiceNumberShort}${payment.invoiceId} - ${DateFormat.yMMMd(l10n.localeName).format(payment.date)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            if (payment.method != null)
                              Text(
                                '${l10n.paymentMethod}: ${payment.method}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          currencyFormat.format(payment.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          context.pushNamed(
                            'client_details',
                            pathParameters: {'id': payment.clientId.toString()},
                          );
                        },
                      ),
                    );
                  }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('${l10n.error}: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${l10n.error}: $e')),
      ),
    );
  }

  Future<void> _sendReminder(
    BuildContext context,
    WidgetRef ref,
    dynamic invoice,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final clientName = invoice.client?.name ?? l10n.unknownClient;
    await Share.share(
      '${l10n.sendReminder}: ${invoice.invoiceNumber}\n'
      '${l10n.clientName}: $clientName\n'
      '${l10n.remainingToPay}: ${invoice.total.toStringAsFixed(2)} ${l10n.currencySymbol}',
      subject: '${l10n.sendReminder} ${invoice.invoiceNumber}',
    );
    await ref
        .read(invoiceRepositoryProvider)
        .updateLastReminderAt(invoice.id, DateTime.now());
    ref.invalidate(invoicesListProvider());
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.reminderLogged)));
  }
}
