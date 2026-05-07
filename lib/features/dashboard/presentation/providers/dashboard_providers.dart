import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../clients/presentation/providers/client_providers.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../../../invoices/presentation/providers/invoice_providers.dart';

part 'dashboard_providers.g.dart';

@riverpod
class DashboardStats extends _$DashboardStats {
  @override
  Future<Map<String, dynamic>> build() async {
    final invoices = await ref.watch(filteredInvoicesProvider.future);
    final clients = await ref.watch(clientsListProvider.future);

    final totalRevenue = invoices
        .where((i) => i.status == InvoiceStatus.paid)
        .fold(0.0, (sum, i) => sum + i.total);

    final outstandingAmount = invoices
        .where((i) => i.status == InvoiceStatus.sent || i.status == InvoiceStatus.overdue)
        .fold(0.0, (sum, i) => sum + i.total);

    final now = DateTime.now();
    final invoicesThisMonth = invoices
        .where((i) => i.issueDate.month == now.month && i.issueDate.year == now.year)
        .length;

    final recentInvoices = [...invoices]
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    
    final overdueInvoices = invoices
        .where((i) => i.status == InvoiceStatus.overdue)
        .toList();

    return {
      'totalRevenue': totalRevenue,
      'outstandingAmount': outstandingAmount,
      'totalClients': clients.length,
      'invoicesThisMonth': invoicesThisMonth,
      'recentInvoices': recentInvoices.take(5).toList(),
      'overdueInvoices': overdueInvoices,
    };
  }
}
