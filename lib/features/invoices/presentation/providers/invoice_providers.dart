import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_status.dart';
import '../../domain/repositories/invoice_repository.dart';

part 'invoice_providers.g.dart';

@riverpod
InvoiceRepository invoiceRepository(InvoiceRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return InvoiceRepositoryImpl(db);
}

@riverpod
Stream<List<Invoice>> invoicesList(InvoicesListRef ref, {InvoiceStatus? status}) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.watchInvoices(status: status);
}

@riverpod
class InvoiceFilterStatus extends _$InvoiceFilterStatus {
  @override
  InvoiceStatus? build() => null;

  void set(InvoiceStatus? status) => state = status;
}

@riverpod
class InvoiceSearchQuery extends _$InvoiceSearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}

@riverpod
class InvoicePeriodTab extends _$InvoicePeriodTab {
  @override
  int build() => 1; // Default index: 1 (This Month / Ce mois)

  void set(int index) => state = index;
}

@riverpod
class InvoiceDateRange extends _$InvoiceDateRange {
  @override
  DateTimeRange? build() => null;

  void set(DateTimeRange? range) => state = range;
}

@riverpod
class PaginatedInvoices extends _$PaginatedInvoices {
  int _currentPage = 0;
  static const int pageSize = 15;
  bool _hasMore = true;

  @override
  Future<List<Invoice>> build() async {
    _currentPage = 0;
    _hasMore = true;
    return _fetchInvoices();
  }

  Future<List<Invoice>> _fetchInvoices() async {
    final status = ref.watch(invoiceFilterStatusProvider);
    final query = ref.watch(invoiceSearchQueryProvider);
    final periodIndex = ref.watch(invoicePeriodTabProvider);
    final dateRange = ref.watch(invoiceDateRangeProvider);
    final repository = ref.watch(invoiceRepositoryProvider);

    DateTime? startDate;
    DateTime? endDate;

    if (dateRange != null) {
      startDate = dateRange.start;
      endDate = dateRange.end;
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      switch (periodIndex) {
        case 0: // This Week
          startDate = today.subtract(Duration(days: today.weekday - 1));
          break;
        case 1: // This Month
          startDate = DateTime(now.year, now.month);
          endDate = DateTime(now.year, now.month + 1).subtract(const Duration(days: 1));
          break;
        case 2: // Last Month
          startDate = DateTime(now.year, now.month - 1);
          endDate = DateTime(now.year, now.month).subtract(const Duration(days: 1));
          break;
      }
    }

    final list = await repository.getInvoices(
      status: status,
      query: query,
      startDate: startDate,
      endDate: endDate,
      limit: pageSize,
      offset: 0,
    );

    if (list.length < pageSize) {
      _hasMore = false;
    }

    return list;
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading || state.isRefreshing || state.isReloading) return;

    final status = ref.read(invoiceFilterStatusProvider);
    final query = ref.read(invoiceSearchQueryProvider);
    final periodIndex = ref.read(invoicePeriodTabProvider);
    final dateRange = ref.read(invoiceDateRangeProvider);
    final repository = ref.read(invoiceRepositoryProvider);

    DateTime? startDate;
    DateTime? endDate;

    if (dateRange != null) {
      startDate = dateRange.start;
      endDate = dateRange.end;
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      switch (periodIndex) {
        case 0:
          startDate = today.subtract(Duration(days: today.weekday - 1));
          break;
        case 1:
          startDate = DateTime(now.year, now.month);
          endDate = DateTime(now.year, now.month + 1).subtract(const Duration(days: 1));
          break;
        case 2:
          startDate = DateTime(now.year, now.month - 1);
          endDate = DateTime(now.year, now.month).subtract(const Duration(days: 1));
          break;
      }
    }

    _currentPage++;
    final nextPage = await repository.getInvoices(
      status: status,
      query: query,
      startDate: startDate,
      endDate: endDate,
      limit: pageSize,
      offset: _currentPage * pageSize,
    );

    if (nextPage.isEmpty || nextPage.length < pageSize) {
      _hasMore = false;
    }

    state = AsyncValue.data([
      ...?state.value,
      ...nextPage,
    ]);
  }

  bool get hasMore => _hasMore;
}

@riverpod
Future<List<Invoice>> filteredInvoices(FilteredInvoicesRef ref) {
  final status = ref.watch(invoiceFilterStatusProvider);
  final query = ref.watch(invoiceSearchQueryProvider);
  final repository = ref.watch(invoiceRepositoryProvider);
  
  return repository.getInvoices(status: status, query: query);
}

@riverpod
Future<Invoice?> invoiceById(InvoiceByIdRef ref, int id) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getInvoiceById(id);
}
