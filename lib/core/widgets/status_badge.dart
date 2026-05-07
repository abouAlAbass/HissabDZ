import 'package:flutter/material.dart';
import 'package:invoice_app/core/theme/theme.dart';
import '../../features/invoices/domain/entities/invoice_status.dart';
import '../../l10n/app_localizations.dart';

class StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;
    
    switch (status) {
      case InvoiceStatus.draft:
        color = AppTheme.textSecondary;
        label = l10n.draft;
        break;
      case InvoiceStatus.sent:
        color = AppTheme.statusIssued;
        label = l10n.sent;
        break;
      case InvoiceStatus.accepted:
        color = AppTheme.statusAccepted;
        label = l10n.accepted;
        break;
      case InvoiceStatus.converted:
        color = AppTheme.statusConverted;
        label = l10n.converted;
        break;
      case InvoiceStatus.paid:
        color = AppTheme.statusPaid;
        label = l10n.paid;
        break;
      case InvoiceStatus.unpaid:
        color = AppTheme.statusOverdue;
        label = l10n.unpaid;
        break;
      case InvoiceStatus.cancelled:
        color = AppTheme.statusCancelled;
        label = l10n.cancelled;
        break;
      case InvoiceStatus.overdue:
        color = AppTheme.statusOverdue;
        label = l10n.overdue;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
