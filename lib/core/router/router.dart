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
import '../widgets/app_drawer.dart';

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
        path: '/invoices/:id/edit',
        name: 'edit_invoice',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '') ?? 0;
          return CreateInvoiceScreen(invoiceId: id);
        },
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
      drawer: const AppDrawer(),
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('create_invoice'),
        backgroundColor: AppTheme.primaryIndigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryIndigo,
        unselectedItemColor: AppTheme.textSecondary,
        showUnselectedLabels: true,
        onTap: (index) {
          switch (index) {
            case 0:
              context.goNamed('dashboard');
              break;
            case 1:
              context.goNamed('clients');
              break;
            case 2:
              context.goNamed('invoices');
              break;
            case 3:
              context.goNamed('payments');
              break;
            case 4:
              context.goNamed('articles');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_rounded),
            label: l10n.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_rounded),
            label: l10n.clients,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.description_rounded),
            label: l10n.invoices,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.payments_rounded),
            label: l10n.payments,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_rounded),
            label: l10n.articles,
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/clients')) return 1;
    if (location.startsWith('/invoices')) return 2;
    if (location.startsWith('/payments')) return 3;
    if (location.startsWith('/articles')) return 4;
    return 0;
  }
}
