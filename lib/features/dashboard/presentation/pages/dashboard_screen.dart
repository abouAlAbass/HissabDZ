import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_providers.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../clients/presentation/pages/client_list_screen.dart';
import '../../../projects/presentation/widgets/expense_form_sheet.dart';
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
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(
            tooltip: l10n.globalSearch,
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed('global_search'),
          ),
        ],
      ),
      drawer: MediaQuery.sizeOf(context).width >= 1100
          ? null
          : const AppDrawer(),
      body: statsAsync.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardStatsProvider.future),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final horizontalPadding = width >= 1100 ? 28.0 : 16.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  width < 720 ? 112 : 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickActions(context, l10n),
                        const SizedBox(height: 20),
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
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${l10n.error}: $e')),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    final actions = [
      (
        label: l10n.createQuote,
        icon: Icons.request_quote_outlined,
        color: Colors.indigo,
        onTap: () => context.pushNamed('create_quote'),
      ),
      (
        label: l10n.addExpense,
        icon: Icons.receipt_long_outlined,
        color: Colors.red,
        onTap: () => _showExpenseSheet(context),
      ),
      (
        label: l10n.quickClient,
        icon: Icons.person_add_alt_1_outlined,
        color: Colors.blue,
        onTap: () => _showClientSheet(context),
      ),
      (
        label: l10n.quickArticle,
        icon: Icons.add_box_outlined,
        color: Colors.green,
        onTap: () => context.pushNamed('add_article'),
      ),
    ];

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1100 ? 4 : 2;
    final childAspectRatio = width >= 1100 ? 3.2 : 2.45;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return FilledButton.icon(
          onPressed: action.onTap,
          icon: Icon(action.icon, size: 24),
          label: Text(
            action.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: action.color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  void _showExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const ExpenseFormSheet(),
    );
  }

  void _showClientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          const Padding(padding: EdgeInsets.all(16), child: AddClientForm()),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> stats,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1100
        ? 3
        : width >= 720
        ? 3
        : 2;
    final childAspectRatio = width >= 720 ? 2.0 : 1.45;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: childAspectRatio,
      children: [
        _buildStatCard(
          context,
          l10n.collectedThisMonth,
          currencyFormat.format(stats['collectedThisMonth']),
          Icons.account_balance_wallet_outlined,
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
          l10n.monthlyExpenses,
          currencyFormat.format(stats['expensesThisMonth']),
          Icons.receipt_long_outlined,
          Colors.red,
        ),
        _buildStatCard(
          context,
          l10n.estimatedProfit,
          currencyFormat.format(stats['estimatedProfit']),
          Icons.trending_up,
          Colors.purple,
        ),
        _buildStatCard(
          context,
          l10n.ongoingProjects,
          '${stats['ongoingProjects']}',
          Icons.construction_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          l10n.overdueInvoices,
          '${stats['overdueInvoiceCount']}',
          Icons.warning_amber_rounded,
          Colors.deepOrange,
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
