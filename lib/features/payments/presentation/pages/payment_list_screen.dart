import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../providers/payment_providers.dart';

class PaymentListScreen extends ConsumerWidget {
  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final paymentsAsync = ref.watch(paymentsListProvider);
    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.payments),
      ),
      drawer: const AppDrawer(),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(l10n.noPayments, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: const Icon(Icons.call_received, color: Colors.green),
                  ),
                  title: Text(
                    payment.client?.name ?? 'Unknown Client',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice #${payment.invoiceId} • ${DateFormat.yMMMd().format(payment.date)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      if (payment.method != null)
                        Text(
                          '${l10n.paymentMethod}: ${payment.method}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
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
                    context.pushNamed('client_details', pathParameters: {'id': payment.clientId.toString()});
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
