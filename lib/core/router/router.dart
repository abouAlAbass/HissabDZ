import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/clients/presentation/pages/client_list_screen.dart';
import '../../features/clients/presentation/pages/client_details_screen.dart';
import '../../features/invoices/presentation/pages/invoice_list_screen.dart';
import '../../features/invoices/presentation/pages/invoice_details_screen.dart';
import '../../features/invoices/presentation/pages/create_invoice_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/payments/presentation/pages/payment_list_screen.dart';
import '../../features/articles/presentation/pages/article_list_screen.dart';
import '../../features/articles/presentation/pages/add_edit_article_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // 1. SHELL ROUTES (With Bottom Navigation Bar)
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/clients',
            name: 'clients',
            builder: (context, state) => const ClientListScreen(),
          ),
          GoRoute(
            path: '/invoices',
            name: 'invoices',
            builder: (context, state) => const InvoiceListScreen(),
          ),
          GoRoute(
            path: '/payments',
            name: 'payments',
            builder: (context, state) => const PaymentListScreen(),
          ),
          GoRoute(
            path: '/articles',
            name: 'articles',
            builder: (context, state) => const ArticleListScreen(),
          ),
        ],
      ),

      // 2. FULL SCREEN ROUTES (Above Bottom Navigation Bar)
      GoRoute(
        path: '/articles/add',
        name: 'add_article',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddEditArticleScreen(),
      ),
      GoRoute(
        path: '/articles/edit/:id',
        name: 'edit_article',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '') ?? 0;
          return AddEditArticleScreen(articleId: id);
        },
      ),
      // These are siblings to the ShellRoute, so they use the root navigator
      GoRoute(
        path: '/clients/:id',
        name: 'client_details',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '') ?? 0;
          return ClientDetailsScreen(clientId: id);
        },
      ),
      GoRoute(
        path: '/invoices/create',
        name: 'create_invoice',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateInvoiceScreen(),
      ),
      GoRoute(
        path: '/invoices/:id',
        name: 'invoice_details',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '') ?? 0;
          return InvoiceDetailsScreen(invoiceId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithBottomNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String location = GoRouterState.of(context).matchedLocation;
    final int selectedIndex = _calculateSelectedIndex(location);

    return Scaffold(
      extendBody: true, // Allow body to flow under bottom nav if needed
      body: child,
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              icon: Icons.description_rounded,
              label: l10n.invoices,
              isActive: selectedIndex == 0,
              onTap: () => context.goNamed('invoices'),
            ),
            _buildCreateButton(context),
            _buildNavItem(
              context,
              icon: Icons.person_rounded,
              label: l10n.settings == 'Settings' ? 'Account' : l10n.settings,
              isActive: selectedIndex == 2,
              onTap: () => context.goNamed('settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    final color = isActive ? AppTheme.primaryIndigo : AppTheme.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: isActive ? BoxDecoration(
              color: AppTheme.primaryIndigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ) : null,
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed('create_invoice'),
      child: Transform.translate(
        offset: const Offset(0, -15),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryIndigo,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryIndigo.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/invoices')) return 0;
    if (location.startsWith('/settings')) return 2;
    return 0; // Default to invoices
  }
}
