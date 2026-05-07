import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:invoice_app/core/theme/theme.dart';
import 'package:invoice_app/core/widgets/status_badge.dart';
import 'package:invoice_app/features/invoices/presentation/providers/invoice_providers.dart';
import 'package:invoice_app/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_app/l10n/app_localizations.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ["This week", "This month", "Last month"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, l10n),
          SliverToBoxAdapter(
            child: invoicesAsync.when(
              data: (invoices) => _buildGroupedList(context, invoices, l10n),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              )),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom spacing
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppTheme.primaryIndigo,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
          child: Column(
            children: [
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.invoices, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        _headerIconButton(Icons.access_time_rounded),
                        const SizedBox(width: 10),
                        _headerIconButton(Icons.search_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _buildSegmentedTabs(),
              const SizedBox(height: 30),
              _buildStatsRow(),
              const Spacer(),
              ClipPath(
                clipper: WaveClipper(),
                child: Container(height: 40, color: AppTheme.background),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        labelColor: AppTheme.primaryIndigo,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem("41", "Issued"),
          _statDivider(),
          _statItem("27", "Paid"),
          _statDivider(),
          _statItem("3", "Overdue"),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statDivider() {
    return Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.2));
  }

  Widget _buildGroupedList(BuildContext context, List<Invoice> invoices, AppLocalizations l10n) {
    if (invoices.isEmpty) return _buildEmptyState(l10n);

    // Group by date
    final Map<String, List<Invoice>> grouped = {};
    for (var inv in invoices) {
      final date = DateFormat('MMMM dd, yyyy').format(inv.issueDate);
      grouped.putIfAbsent(date, () => []).add(inv);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final items = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              date.toUpperCase(),
              style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final inv = entry.value;
              return _buildAnimatedInvoiceCard(context, inv, i);
            }),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedInvoiceCard(BuildContext context, Invoice invoice, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: _buildInvoiceCard(context, invoice),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice) {
    final l10n = AppLocalizations.of(context)!;
    final initials = invoice.client?.name.substring(0, 1).toUpperCase() ?? "??";
    
    // Custom avatar color based on initials (simplified for demo)
    final avatarColor = _getAvatarColor(initials);

    return Hero(
      tag: 'invoice_${invoice.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: InkWell(
            onTap: () => context.pushNamed('invoice_details', pathParameters: {'id': invoice.id.toString()}),
            borderRadius: BorderRadius.circular(16),
            splashColor: AppTheme.primaryIndigo.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: avatarColor.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(initials, style: TextStyle(color: avatarColor.text, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.client?.name ?? "Unknown Client",
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(status: invoice.status),
                      ],
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: l10n.currencySymbol).format(invoice.total),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AvatarColor _getAvatarColor(String initials) {
    const colors = [
      AvatarColor(Color(0xFFEDE9FE), Color(0xFF6D28D9)), // NJ
      AvatarColor(Color(0xFFDBEAFE), Color(0xFF1D4ED8)), // MG
      AvatarColor(Color(0xFFFCE7F3), Color(0xFF9D174D)), // LM
      AvatarColor(Color(0xFFFEF3C7), Color(0xFFB45309)), // H9
      AvatarColor(Color(0xFFCCFBF1), Color(0xFF0F766E)), // TL
      AvatarColor(Color(0xFFD1FAE5), Color(0xFF059669)), // IG
    ];
    return colors[initials.codeUnitAt(0) % colors.length];
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.description_outlined, size: 80, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(l10n.noInvoices, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, 0);
    path.lineTo(0, size.height);
    
    var firstControlPoint = Offset(size.width / 4, 0);
    var firstEndPoint = Offset(size.width / 2.25, size.height / 1.5);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height + 10);
    var secondEndPoint = Offset(size.width, size.height / 2);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class AvatarColor {
  final Color bg;
  final Color text;
  const AvatarColor(this.bg, this.text);
}
