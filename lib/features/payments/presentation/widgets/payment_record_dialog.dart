import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hissab_dz/features/invoices/domain/entities/invoice.dart';
import 'package:hissab_dz/features/invoices/domain/entities/invoice_status.dart';
import 'package:hissab_dz/features/invoices/presentation/providers/invoice_providers.dart';
import 'package:hissab_dz/features/payments/domain/entities/payment.dart';
import 'package:hissab_dz/features/payments/presentation/providers/payment_providers.dart';
import 'package:hissab_dz/features/payments/data/repositories/payment_repository.dart';
import 'package:hissab_dz/l10n/app_localizations.dart';

class PaymentRecordDialog extends ConsumerStatefulWidget {
  final Invoice invoice;

  const PaymentRecordDialog({super.key, required this.invoice});

  @override
  ConsumerState<PaymentRecordDialog> createState() => _PaymentRecordDialogState();
}

class _PaymentRecordDialogState extends ConsumerState<PaymentRecordDialog> {
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.invoice.total.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);

    return AlertDialog(
      title: Text(l10n.recordPayment),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${l10n.outstanding}: ${currencyFormat.format(widget.invoice.total)}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.paymentAmount,
              prefixText: '${l10n.currencySymbol} ',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
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
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _savePayment,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.record),
        ),
      ],
    );
  }

  Future<void> _savePayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final payment = Payment(
        invoiceId: widget.invoice.id!,
        clientId: widget.invoice.clientId,
        amount: amount,
        date: DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await ref.read(paymentRepositoryProvider).addPayment(payment);

      final payments = await ref.read(invoicePaymentsProvider(widget.invoice.id!).future);
      final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount) + amount;

      final newStatus = totalPaid >= widget.invoice.total ? InvoiceStatus.paid : InvoiceStatus.sent;
      
      final updatedInvoice = widget.invoice.copyWith(status: newStatus);
      await ref.read(invoiceRepositoryProvider).updateInvoice(updatedInvoice);

      // Invalidate providers to refresh UI
      ref.invalidate(invoicePaymentsProvider(widget.invoice.id!));
      ref.invalidate(invoicesListProvider);
      ref.invalidate(filteredInvoicesProvider);
      ref.invalidate(invoiceByIdProvider(widget.invoice.id!));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.paymentRecorded}: ${NumberFormat.currency(symbol: l10n.currencySymbol).format(amount)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
