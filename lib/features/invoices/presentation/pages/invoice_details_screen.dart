import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/invoice_providers.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_status.dart';
import 'package:hissab_dz/core/theme/theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../services/pdf_invoice_service.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../settings/domain/entities/business_profile.dart';
import 'package:hissab_dz/l10n/app_localizations.dart';
import 'package:hissab_dz/features/payments/domain/entities/payment.dart';
import 'package:hissab_dz/features/payments/presentation/providers/payment_providers.dart';
import 'package:hissab_dz/features/payments/data/repositories/payment_repository.dart';

class InvoiceDetailsScreen extends ConsumerWidget {
  final int invoiceId;
  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesListProvider());
    final businessProfileAsync = ref.watch(businessProfileProvider);
    final businessProfile = businessProfileAsync.value;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoiceDetails),
        actions: [
          IconButton(
            tooltip: l10n.downloadPdf,
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _downloadPdf(context, ref, businessProfile),
          ),
          IconButton(
            tooltip: l10n.share,
            icon: const Icon(Icons.share),
            onPressed: () => _sharePdf(context, ref, businessProfile),
          ),
          IconButton(
            tooltip: l10n.editInvoice,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.pushNamed(
              'edit_invoice',
              pathParameters: {'id': invoiceId.toString()},
            ),
          ),
        ],
      ),
      body: invoicesAsync.when(
        data: (invoices) {
          final index = invoices.indexWhere((i) => i.id == invoiceId);
          if (index == -1) {
            return Center(child: Text(l10n.invoiceNotFound));
          }
          final invoice = invoices[index];
          return Hero(
            tag: 'invoice_${invoice.id}',
            child: Material(
              color: Colors.transparent,
              child: _InvoiceDetailsBody(
                invoice: invoice,
                onSharePdf: () => _sharePdf(context, ref, businessProfile),
                onDownloadPdf: () =>
                    _downloadPdf(context, ref, businessProfile),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('${l10n.error}: $e')),
      ),
    );
  }

  Future<void> _downloadPdf(
    BuildContext context,
    WidgetRef ref,
    BusinessProfile? profile,
  ) async {
    final invoices = ref.read(invoicesListProvider()).value ?? [];
    final index = invoices.indexWhere((i) => i.id == invoiceId);
    if (index == -1) return;

    final invoice = invoices[index];
    final l10n = AppLocalizations.of(context)!;

    try {
      // Generate PDF in temp first
      final tempFile = await PdfInvoiceService.generateInvoicePdf(
        invoice: invoice,
        profile: profile,
        l10n: l10n,
      );

      // Save to Downloads folder
      Directory? downloadsDir;
      if (Platform.isWindows) {
        downloadsDir = await getDownloadsDirectory();
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final saveDir = Directory(p.join(downloadsDir!.path, 'InvoicePro'));
      if (!saveDir.existsSync()) saveDir.createSync(recursive: true);

      String savedPath = p.join(
        saveDir.path,
        'invoice_${invoice.invoiceNumber}.pdf',
      );
      final targetFile = File(savedPath);

      try {
        if (targetFile.existsSync()) {
          await targetFile.delete();
        }
      } catch (e) {
        // If file is locked/open, use a timestamped filename
        final timestamp = DateFormat('HHmmss').format(DateTime.now());
        savedPath = p.join(
          saveDir.path,
          'invoice_${invoice.invoiceNumber}_$timestamp.pdf',
        );
      }

      await tempFile.copy(savedPath);

      // Open the file immediately
      await OpenFilex.open(savedPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.pdfDownloadedAndOpened}\n${p.basename(savedPath)}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf(
    BuildContext context,
    WidgetRef ref,
    BusinessProfile? profile,
  ) async {
    final invoices = ref.read(invoicesListProvider()).value ?? [];
    final index = invoices.indexWhere((i) => i.id == invoiceId);
    if (index == -1) return;

    final invoice = invoices[index];
    final l10n = AppLocalizations.of(context)!;

    try {
      final file = await PdfInvoiceService.generateInvoicePdf(
        invoice: invoice,
        profile: profile,
        l10n: l10n,
      );
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: '${l10n.invoiceLabel} ${invoice.invoiceNumber}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorGeneratingPdf}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ── Stateful body widget ──────────────────────────────────────────────────────
class _InvoiceDetailsBody extends ConsumerStatefulWidget {
  final Invoice invoice;
  final VoidCallback onSharePdf;
  final VoidCallback onDownloadPdf;

  const _InvoiceDetailsBody({
    required this.invoice,
    required this.onSharePdf,
    required this.onDownloadPdf,
  });

  @override
  ConsumerState<_InvoiceDetailsBody> createState() =>
      _InvoiceDetailsBodyState();
}

class _InvoiceDetailsBodyState extends ConsumerState<_InvoiceDetailsBody> {
  late InvoiceStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.invoice.status;
  }

  @override
  void didUpdateWidget(_InvoiceDetailsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoice.status != widget.invoice.status) {
      _currentStatus = widget.invoice.status;
    }
  }

  // ─── Status Update ────────────────────────────────────────────────────────
  Future<void> _updateStatus(InvoiceStatus newStatus) async {
    final updated = widget.invoice.copyWith(status: newStatus);
    await ref.read(invoiceRepositoryProvider).updateInvoice(updated);
    if (mounted) setState(() => _currentStatus = newStatus);
  }

  void _showStatusDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.updateStatus),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: InvoiceStatus.values.map((status) {
            String label;
            switch (status) {
              case InvoiceStatus.draft:
                label = l10n.draft;
                break;
              case InvoiceStatus.sent:
                label = l10n.sent;
                break;
              case InvoiceStatus.accepted:
                label = l10n.accepted;
                break;
              case InvoiceStatus.converted:
                label = l10n.converted;
                break;
              case InvoiceStatus.paid:
                label = l10n.paid;
                break;
              case InvoiceStatus.unpaid:
                label = l10n.unpaid;
                break;
              case InvoiceStatus.cancelled:
                label = l10n.cancelled;
                break;
              case InvoiceStatus.overdue:
                label = l10n.overdue;
                break;
            }

            return ListTile(
              leading: _statusIcon(status),
              title: Text(label),
              trailing: _currentStatus == status
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                if (status != _currentStatus) {
                  await _updateStatus(status);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.statusUpdated}: $label')),
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Icon _statusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return const Icon(Icons.edit_note, color: AppTheme.textSecondary);
      case InvoiceStatus.sent:
        return const Icon(Icons.send, color: AppTheme.statusIssued);
      case InvoiceStatus.accepted:
        return const Icon(
          Icons.check_circle_outline,
          color: AppTheme.statusAccepted,
        );
      case InvoiceStatus.converted:
        return const Icon(
          Icons.description_outlined,
          color: AppTheme.statusConverted,
        );
      case InvoiceStatus.paid:
        return const Icon(Icons.check_circle, color: AppTheme.statusPaid);
      case InvoiceStatus.unpaid:
        return const Icon(Icons.money_off, color: AppTheme.statusOverdue);
      case InvoiceStatus.cancelled:
        return const Icon(
          Icons.cancel_outlined,
          color: AppTheme.statusCancelled,
        );
      case InvoiceStatus.overdue:
        return const Icon(Icons.warning, color: AppTheme.statusOverdue);
    }
  }

  // ─── Record Payment ───────────────────────────────────────────────────────
  void _showPaymentDialog() {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController(
      text: widget.invoice.total.toStringAsFixed(2),
    );
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recordPayment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l10n.outstanding}: ${NumberFormat.currency(symbol: l10n.currencySymbol).format(widget.invoice.total)}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.paymentAmount,
                prefixText: '${l10n.currencySymbol} ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: l10n.notesOptional,
                hintText: l10n.paymentNotesHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;

              Navigator.pop(ctx);

              // 1. Save the payment record
              final payment = Payment(
                invoiceId: widget.invoice.id!,
                clientId: widget.invoice.clientId,
                amount: amount,
                date: DateTime.now(),
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );
              await ref.read(paymentRepositoryProvider).addPayment(payment);

              // 2. Calculate new total paid to decide status
              final existingPayments = await ref.read(
                invoicePaymentsProvider(widget.invoice.id!).future,
              );
              final totalPaid =
                  existingPayments.fold(0.0, (sum, p) => sum + p.amount) +
                  amount;

              // 3. Mark as paid when a full (or over) payment is recorded
              final newStatus = totalPaid >= widget.invoice.total
                  ? InvoiceStatus.paid
                  : InvoiceStatus.sent;

              await _updateStatus(newStatus);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${l10n.paymentRecorded}: ${NumberFormat.currency(symbol: l10n.currencySymbol).format(amount)}'
                      '${newStatus == InvoiceStatus.paid ? ' - ${l10n.invoiceMarkedPaid}' : ''}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(l10n.record),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            DateFormat.yMMMd().format(invoice.issueDate),
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (invoice.dueDate != null)
                            Text(
                              '${l10n.dueDate}: ${DateFormat.yMMMd().format(invoice.dueDate!)}',
                              style: TextStyle(
                                color: invoice.status == InvoiceStatus.overdue
                                    ? Colors.red
                                    : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          if (invoice.projectName != null)
                            Text(
                              '${l10n.project}: ${invoice.projectName}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusBadge(status: _currentStatus),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _showStatusDialog,
                            icon: const Icon(Icons.swap_horiz, size: 16),
                            label: Text(
                              l10n.changeStatus,
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showPaymentDialog,
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(l10n.recordPayment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onDownloadPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.exportPdf),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bill To
          _sectionTitle(l10n.billTo),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text((invoice.client?.name ?? '?')[0].toUpperCase()),
              ),
              title: Text(
                invoice.client?.name ?? l10n.unknownClient,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (invoice.client?.email != null)
                    Text(invoice.client!.email!),
                  if (invoice.client?.phone != null)
                    Text(invoice.client!.phone!),
                  if (invoice.client?.address != null)
                    Text(invoice.client!.address!),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Items
          _sectionTitle('${l10n.items} (${invoice.items.length})'),
          Card(
            child: Column(
              children: [
                // header row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          l10n.quantity,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          l10n.price,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          l10n.amount,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...invoice.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Container(
                    color: i.isOdd ? Colors.grey.withAlpha(20) : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.description)),
                        SizedBox(
                          width: 60,
                          child: Text(
                            item.quantity.toString(),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            currencyFormat.format(item.unitPrice),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            currencyFormat.format(item.amount),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Totals / Balance
          _sectionTitle(l10n.summary),
          ref
              .watch(invoicePaymentsProvider(invoice.id!))
              .when(
                data: (payments) {
                  final paidAmount = payments.fold(
                    0.0,
                    (sum, p) => sum + p.amount,
                  );
                  final remainingAmount = invoice.total - paidAmount;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _totalRow(
                            l10n.subtotal,
                            currencyFormat.format(invoice.subtotal),
                          ),
                          const SizedBox(height: 6),
                          _totalRow(
                            '${l10n.totalTax} (${invoice.taxRate}%)',
                            currencyFormat.format(
                              invoice.subtotal * invoice.taxRate / 100,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _totalRow(
                            l10n.discount,
                            '- ${currencyFormat.format(invoice.discountAmount)}',
                          ),
                          const Divider(height: 20),
                          _totalRow(
                            l10n.total,
                            currencyFormat.format(invoice.total),
                            isBold: true,
                            fontSize: 16,
                          ),
                          const SizedBox(height: 6),
                          _totalRow(
                            l10n.paidAmount,
                            currencyFormat.format(paidAmount),
                            color: Colors.green,
                            fontSize: 16,
                          ),
                          const Divider(height: 20),
                          _totalRow(
                            l10n.remaining,
                            currencyFormat.format(
                              remainingAmount < 0 ? 0 : remainingAmount,
                            ),
                            isBold: true,
                            fontSize: 18,
                            color: remainingAmount > 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),

          const SizedBox(height: 20),

          // Related Payments
          _sectionTitle(l10n.relatedPayments),
          ref
              .watch(invoicePaymentsProvider(invoice.id!))
              .when(
                data: (payments) {
                  if (payments.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            l10n.noPayments,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return Card(
                    child: Column(
                      children: payments
                          .map(
                            (p) => ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.payment,
                                size: 18,
                                color: Colors.green,
                              ),
                              title: Text(
                                currencyFormat.format(p.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(DateFormat.yMMMd().format(p.date)),
                              trailing: p.notes != null
                                  ? const Icon(Icons.info_outline, size: 14)
                                  : null,
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),

          // Notes
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle(l10n.notes),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  invoice.notes!,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : null,
      fontSize: fontSize,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
