import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hissab_dz/core/theme/theme.dart';
import 'package:hissab_dz/core/widgets/app_drawer.dart';
import 'package:hissab_dz/core/widgets/status_badge.dart';
import 'package:hissab_dz/features/invoices/domain/entities/invoice.dart';
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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invoicesAsync = ref.watch(filteredInvoicesProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.invoices),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
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
                const SizedBox(height: 12),
                _buildPeriodTabs(l10n),
              ],
            ),
          ),
        ),
      ),
      body: invoicesAsync.when(
        data: (invoices) {
          final visibleInvoices = _filterInvoicesBySelectedTab(invoices);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: _buildStatsCard(visibleInvoices, l10n),
                ),
              ),
              if (visibleInvoices.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(l10n),
                )
              else
                _buildGroupedSliverList(context, visibleInvoices, l10n),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
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
        unselectedLabelColor: AppTheme.textSecondary,
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
    final paidCount = invoices
        .where((invoice) => invoice.status.name == 'paid')
        .length;
    final overdueCount = invoices
        .where((invoice) => invoice.status.name == 'overdue')
        .length;
    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);
    final total = invoices.fold(0.0, (sum, invoice) => sum + invoice.total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _statItem(invoices.length.toString(), l10n.issued)),
            _statDivider(),
            Expanded(child: _statItem(paidCount.toString(), l10n.paid)),
            _statDivider(),
            Expanded(child: _statItem(overdueCount.toString(), l10n.overdue)),
            _statDivider(),
            Expanded(
              child: _statItem(
                currencyFormat.format(total),
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
            color: AppTheme.textPrimary,
            fontSize: compact ? 15 : 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textSecondary,
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
      final date = DateFormat.yMMMMd(l10n.localeName).format(invoice.issueDate);
      grouped.putIfAbsent(date, () => []).add(invoice);
    }

    final children = <Widget>[];
    for (final entry in grouped.entries) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(
            entry.key.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textSecondary,
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

  List<Invoice> _filterInvoicesBySelectedTab(List<Invoice> invoices) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfThisMonth = DateTime(now.year, now.month);
    final startOfLastMonth = DateTime(now.year, now.month - 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1);

    return invoices.where((invoice) {
      final date = DateTime(
        invoice.issueDate.year,
        invoice.issueDate.month,
        invoice.issueDate.day,
      );
      switch (_tabController.index) {
        case 0:
          return !date.isBefore(startOfThisWeek);
        case 1:
          return !date.isBefore(startOfThisMonth) &&
              date.isBefore(startOfNextMonth);
        case 2:
          return !date.isBefore(startOfLastMonth) &&
              date.isBefore(startOfThisMonth);
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    Invoice invoice,
    AppLocalizations l10n,
  ) {
    final initials = invoice.client?.name.substring(0, 1).toUpperCase() ?? "?";
    final avatarColor = _getAvatarColor(initials);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: avatarColor.bg,
            child: Text(
              initials,
              style: TextStyle(
                color: avatarColor.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            invoice.client?.name ?? l10n.unknownClient,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: invoice.status),
              ],
            ),
          ),
          trailing: Text(
            NumberFormat.currency(
              symbol: l10n.currencySymbol,
            ).format(invoice.total),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          onTap: () => context.pushNamed(
            'invoice_details',
            pathParameters: {'id': invoice.id.toString()},
          ),
        ),
      ),
    );
  }

  AvatarColor _getAvatarColor(String initials) {
    const colors = [
      AvatarColor(Color(0xFFEDE9FE), Color(0xFF6D28D9)),
      AvatarColor(Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
      AvatarColor(Color(0xFFFCE7F3), Color(0xFF9D174D)),
      AvatarColor(Color(0xFFFEF3C7), Color(0xFFB45309)),
      AvatarColor(Color(0xFFCCFBF1), Color(0xFF0F766E)),
      AvatarColor(Color(0xFFD1FAE5), Color(0xFF059669)),
    ];
    return colors[initials.codeUnitAt(0) % colors.length];
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 72,
            color: AppTheme.textSecondary.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noInvoices,
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class AvatarColor {
  final Color bg;
  final Color text;
  const AvatarColor(this.bg, this.text);
}
