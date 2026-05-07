import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_providers.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboard)),
      drawer: const AppDrawer(),
      body: statsAsync.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardStatsProvider.future),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryGrid(context, l10n, stats),
                const SizedBox(height: 24),
                if ((stats['overdueInvoices'] as List).isNotEmpty) ...[
                  _buildOverdueAlert(
                    context,
                    l10n,
                    stats['overdueInvoices'] as List<Invoice>,
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  l10n.recentInvoices,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildRecentInvoices(
                  context,
                  l10n,
                  stats['recentInvoices'] as List<Invoice>,
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> stats,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          l10n.totalRevenue,
          currencyFormat.format(stats['totalRevenue']),
          Icons.attach_money,
          Colors.green,
        ),
        _buildStatCard(
          context,
          l10n.outstanding,
          currencyFormat.format(stats['outstandingAmount']),
          Icons.pending_actions,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          l10n.totalClients,
          '${stats['totalClients']}',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          l10n.thisMonth,
          '${stats['invoicesThisMonth']}',
          Icons.description,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueAlert(
    BuildContext context,
    AppLocalizations l10n,
    List<Invoice> overdue,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: Icon(
          Icons.warning,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
          l10n.overdueAlert(overdue.length),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          l10n.immediateAction,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed('invoices'),
      ),
    );
  }

  Widget _buildRecentInvoices(
    BuildContext context,
    AppLocalizations l10n,
    List<Invoice> invoices,
  ) {
    if (invoices.isEmpty) {
      return Card(child: ListTile(title: Text(l10n.noRecentInvoices)));
    }

    return Column(
      children: invoices
          .map(
            (invoice) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(invoice.client?.name ?? '—'),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      NumberFormat.currency(
                        symbol: l10n.currencySymbol,
                      ).format(invoice.total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    StatusBadge(status: invoice.status),
                  ],
                ),
                onTap: () => context.pushNamed(
                  'invoice_details',
                  pathParameters: {'id': invoice.id.toString()},
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
