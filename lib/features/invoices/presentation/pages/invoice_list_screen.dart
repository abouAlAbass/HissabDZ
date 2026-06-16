import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hissab_dz/core/utils/app_formatters.dart';
import 'package:hissab_dz/core/theme/theme.dart';
import 'package:hissab_dz/core/widgets/app_empty_state.dart';
import 'package:hissab_dz/core/widgets/app_drawer.dart';
import 'package:hissab_dz/core/widgets/contextual_fab.dart';
import 'package:hissab_dz/core/widgets/entity_card.dart';
import 'package:hissab_dz/core/widgets/status_badge.dart';
import 'package:hissab_dz/features/invoices/domain/entities/invoice.dart';
import 'package:hissab_dz/features/invoices/domain/entities/invoice_status.dart';
import 'package:hissab_dz/features/invoices/presentation/providers/invoice_providers.dart';
import 'package:hissab_dz/l10n/app_localizations.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoicePeriodTabProvider.notifier).set(1);
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(invoicePeriodTabProvider.notifier).set(_tabController.index);
        ref.read(invoiceDateRangeProvider.notifier).set(null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final currentRange = ref.read(invoiceDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: currentRange,
    );
    if (picked != null) {
      ref.read(invoiceDateRangeProvider.notifier).set(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invoicesAsync = ref.watch(paginatedInvoicesProvider);
    final selectedDateRange = ref.watch(invoiceDateRangeProvider);

    return Scaffold(
      drawer: MediaQuery.sizeOf(context).width >= 1100
          ? null
          : const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.invoices),
        actions: [
          IconButton(
            icon: Icon(
              selectedDateRange != null
                  ? Icons.date_range
                  : Icons.date_range_outlined,
              color: selectedDateRange != null ? AppTheme.primaryIndigo : null,
            ),
            onPressed: _selectDateRange,
            tooltip: l10n.selectDateRange,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(selectedDateRange != null ? 166 : 116),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => ref
                            .read(invoiceSearchQueryProvider.notifier)
                            .update(value),
                        decoration: InputDecoration(
                          hintText: l10n.searchInvoices,
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: selectedDateRange != null
                            ? AppTheme.primaryIndigo.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _selectDateRange,
                        icon: Icon(
                          selectedDateRange != null
                              ? Icons.date_range
                              : Icons.date_range_outlined,
                          color: selectedDateRange != null ? AppTheme.primaryIndigo : null,
                        ),
                        tooltip: l10n.selectDateRange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPeriodTabs(l10n),
                if (selectedDateRange != null) ...[
                  const SizedBox(height: 8),
                  InputChip(
                    label: Text(
                      '${l10n.from} ${l10n.localeName == 'ar' ? DateFormat('dd/MM/yyyy', 'en').format(selectedDateRange.start) : DateFormat.yMMMd(l10n.localeName).format(selectedDateRange.start)} ${l10n.to} ${l10n.localeName == 'ar' ? DateFormat('dd/MM/yyyy', 'en').format(selectedDateRange.end) : DateFormat.yMMMd(l10n.localeName).format(selectedDateRange.end)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onDeleted: () {
                      ref.read(invoiceDateRangeProvider.notifier).set(null);
                    },
                    deleteIconColor: Colors.red,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: invoicesAsync.when(
        data: (invoices) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: _buildStatsCard(invoices, l10n),
                ),
              ),
              if (invoices.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(l10n),
                )
              else ...[
                _buildGroupedSliverList(context, invoices, l10n),
                if (ref.watch(paginatedInvoicesProvider.notifier).hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: () {
                            ref
                                .read(paginatedInvoicesProvider.notifier)
                                .loadMore();
                          },
                          child: Text(l10n.loadMore),
                        ),
                      ),
                    ),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${l10n.error}: $e')),
      ),
      floatingActionButton: ContextualFab(
        onPressed: () => context.pushNamed('create_invoice'),
        tooltip: l10n.createInvoice,
        icon: Icons.add,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPeriodTabs(AppLocalizations l10n) {
    final tabs = [l10n.thisWeek, l10n.thisMonth, l10n.lastMonth];

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppTheme.primaryIndigo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        labelColor: AppTheme.primaryIndigo,
        unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: tabs.map((label) => Tab(text: label)).toList(),
      ),
    );
  }

  Widget _buildStatsCard(List<Invoice> invoices, AppLocalizations l10n) {
    final activeInvoices = invoices.where((i) => i.status != InvoiceStatus.cancelled && i.status != InvoiceStatus.draft).toList();
    final paidCount = activeInvoices
        .where((invoice) => invoice.status == InvoiceStatus.paid)
        .length;
    final overdueCount = activeInvoices
        .where((invoice) => invoice.status == InvoiceStatus.overdue)
        .length;
    final total = activeInvoices.fold(0.0, (sum, invoice) => sum + invoice.total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _statItem(activeInvoices.length.toString(), l10n.issued)),
            _statDivider(),
            Expanded(child: _statItem(paidCount.toString(), l10n.paid)),
            _statDivider(),
            Expanded(child: _statItem(overdueCount.toString(), l10n.overdue)),
            _statDivider(),
            Expanded(
              child: _statItem(
                AppFormatters.formatCurrency(total, l10n),
                l10n.total,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, {bool compact = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: compact ? 15 : 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      height: 34,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.black.withValues(alpha: 0.06),
    );
  }

  Widget _buildGroupedSliverList(
    BuildContext context,
    List<Invoice> invoices,
    AppLocalizations l10n,
  ) {
    final grouped = <String, List<Invoice>>{};
    for (final invoice in invoices) {
      final date = l10n.localeName == 'ar'
          ? DateFormat('dd/MM/yyyy', 'en').format(invoice.issueDate)
          : DateFormat.yMMMMd(l10n.localeName).format(invoice.issueDate);
      grouped.putIfAbsent(date, () => []).add(invoice);
    }

    final children = <Widget>[];
    for (final entry in grouped.entries) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(
            entry.key.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );
      children.addAll(
        entry.value.map((invoice) => _buildInvoiceCard(context, invoice, l10n)),
      );
    }

    return SliverList(delegate: SliverChildListDelegate(children));
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    Invoice invoice,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: EntityCard(
        icon: Icons.description_outlined,
        color: AppColors.invoice,
        title: invoice.client?.name ?? l10n.unknownClient,
        subtitle: invoice.invoiceNumber,
        amount: AppFormatters.formatCurrency(invoice.total, l10n),
        badge: StatusBadge(status: invoice.status),
        onTap: () => context.pushNamed(
          'invoice_details',
          pathParameters: {'id': invoice.id.toString()},
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return AppEmptyState(
      icon: Icons.description_outlined,
      title: l10n.noInvoices,
    );
  }
}
