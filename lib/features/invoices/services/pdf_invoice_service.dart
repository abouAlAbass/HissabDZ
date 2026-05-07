import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../domain/entities/invoice.dart';
import '../domain/entities/invoice_status.dart';
import '../../settings/domain/entities/business_profile.dart';
import '../../../l10n/app_localizations.dart';

class PdfInvoiceService {
  // ── Public entry point ────────────────────────────────────────────────────
  static Future<File> generateInvoicePdf({
    required Invoice invoice,
    BusinessProfile? profile,
    required AppLocalizations l10n,
  }) async {
    final isRtl = l10n.localeName == 'ar';
    final textDirection = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    // Load both Latin and Arabic fonts to ensure all characters (mixed text) render correctly
    final notoRegular = await PdfGoogleFonts.notoSansRegular();
    final notoBold = await PdfGoogleFonts.notoSansBold();
    final arabicRegular = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();
    
    // Load logo image if available
    pw.MemoryImage? logoImage;
    if (profile?.logoPath != null) {
      final logoFile = File(profile!.logoPath!);
      if (logoFile.existsSync()) {
        final bytes = await logoFile.readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      }
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: isRtl ? arabicRegular : notoRegular,
        bold: isRtl ? arabicBold : notoBold,
        fontFallback: isRtl ? [notoRegular, notoBold] : [arabicRegular, arabicBold],
      ),
    );

    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        textDirection: textDirection,
        build: (context) => [
          _buildHeader(invoice, profile, logoImage, dateFormat, l10n, isRtl),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 20),
          _buildBillingInfo(invoice, l10n),
          pw.SizedBox(height: 24),
          _buildItemsTable(invoice, currencyFormat, l10n),
          pw.SizedBox(height: 20),
          _buildTotals(invoice, currencyFormat, l10n),
        ],
        footer: (context) => _buildFooter(context, l10n),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── Header: logo + company info + invoice meta ────────────────────────────
  static pw.Widget _buildHeader(Invoice invoice, BusinessProfile? profile, pw.MemoryImage? logo, DateFormat dateFormat, AppLocalizations l10n, bool isRtl) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company Info (Left in LTR, Right in RTL)
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
            children: [
              if (logo != null)
                pw.Container(
                  height: 60,
                  width: 120,
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                )
              else
                pw.Container(
                  height: 60,
                  width: 60,
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text('INV',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800, fontSize: 18)),
                  ),
                ),
              pw.Text(
                profile?.companyName ?? l10n.companyName,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              ),
              if (profile?.address != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(profile!.address!, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
              if (profile?.phone != null)
                pw.Text(profile!.phone!, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              if (profile?.email != null)
                pw.Text(profile!.email!, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              if (profile?.website != null)
                pw.Text(profile!.website!, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        // Invoice Details (Right in LTR, Left in RTL)
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
            children: [
              pw.Text(l10n.invoiceLabel.toUpperCase(),
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
              pw.SizedBox(height: 10),
              _metaRow(l10n.invoiceNumber, invoice.invoiceNumber, isRtl),
              _metaRow(l10n.issueDate, dateFormat.format(invoice.issueDate), isRtl),
              if (invoice.dueDate != null)
                _metaRow(l10n.dueDate, dateFormat.format(invoice.dueDate!), isRtl, valueColor: PdfColors.red800),
              pw.SizedBox(height: 8),
              _buildStatusBadge(invoice.status, l10n),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _metaRow(String label, String value, bool isRtl, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: isRtl ? pw.MainAxisAlignment.start : pw.MainAxisAlignment.end,
        children: [
          pw.Text('$label: ', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text(value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: valueColor ?? PdfColors.black)),
        ],
      ),
    );
  }

  static pw.Widget _buildStatusBadge(InvoiceStatus status, AppLocalizations l10n) {
    PdfColor bg;
    PdfColor fg;
    String label;
    switch (status) {
      case InvoiceStatus.paid:      bg = PdfColors.green100; fg = PdfColors.green800; label = l10n.paid; break;
      case InvoiceStatus.sent:      bg = PdfColors.blue100;  fg = PdfColors.blue800;  label = l10n.sent; break;
      case InvoiceStatus.accepted:  bg = PdfColors.teal100;  fg = PdfColors.teal800;  label = l10n.accepted; break;
      case InvoiceStatus.converted: bg = PdfColors.indigo100;  fg = PdfColors.indigo800;  label = l10n.converted; break;
      case InvoiceStatus.overdue:   bg = PdfColors.red100;   fg = PdfColors.red800;   label = l10n.overdue; break;
      case InvoiceStatus.unpaid:    bg = PdfColors.red100;   fg = PdfColors.red800;   label = l10n.unpaid; break;
      case InvoiceStatus.draft:     bg = PdfColors.grey200;  fg = PdfColors.grey700;  label = l10n.draft; break;
      case InvoiceStatus.cancelled: bg = PdfColors.grey300;  fg = PdfColors.grey800;  label = l10n.cancelled; break;
    }
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(20)),
      child: pw.Text(label.toUpperCase(),
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: fg)),
    );
  }

  // ── Billing Info ──────────────────────────────────────────────────────────
  static pw.Widget _buildBillingInfo(Invoice invoice, AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(l10n.billTo.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          pw.Text(invoice.client?.name ?? '—',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          if (invoice.client?.email != null) pw.Text(invoice.client!.email!, style: const pw.TextStyle(fontSize: 10)),
          if (invoice.client?.phone != null) pw.Text(invoice.client!.phone!, style: const pw.TextStyle(fontSize: 10)),
          if (invoice.client?.address != null) pw.Text(invoice.client!.address!, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // ── Items Table ───────────────────────────────────────────────────────────
  static pw.Widget _buildItemsTable(Invoice invoice, NumberFormat currencyFormat, AppLocalizations l10n) {
    const headerDeco = pw.BoxDecoration(color: PdfColors.blueGrey800);
    const evenDeco = pw.BoxDecoration(color: PdfColors.grey100);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FixedColumnWidth(45),
        2: pw.FixedColumnWidth(80),
        3: pw.FixedColumnWidth(80),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: headerDeco,
          children: [
            _cell(l10n.description, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10)),
            _cell(l10n.quantity,    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10), align: pw.Alignment.centerRight),
            _cell(l10n.price,       style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10), align: pw.Alignment.centerRight),
            _cell(l10n.amount,      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10), align: pw.Alignment.centerRight),
          ],
        ),
        // Data rows with alternating shading
        ...invoice.items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return pw.TableRow(
            decoration: i.isOdd ? evenDeco : null,
            children: [
              _cell(item.description),
              _cell(item.quantity.toString(), align: pw.Alignment.centerRight),
              _cell(currencyFormat.format(item.unitPrice), align: pw.Alignment.centerRight),
              _cell(currencyFormat.format(item.amount),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                align: pw.Alignment.centerRight),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(String text, {pw.TextStyle? style, pw.Alignment? align}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Align(
        alignment: align ?? pw.Alignment.centerLeft,
        child: pw.Text(text, style: style ?? const pw.TextStyle(fontSize: 10)),
      ),
    );
  }

  // ── Totals ────────────────────────────────────────────────────────────────
  static pw.Widget _buildTotals(Invoice invoice, NumberFormat currencyFormat, AppLocalizations l10n) {
    final taxAmount = invoice.subtotal * invoice.taxRate / 100;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Notes (left side)
        pw.Expanded(
          flex: 5,
          child: invoice.notes != null && invoice.notes!.isNotEmpty
              ? pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${l10n.notes}:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                  ],
                )
              : pw.SizedBox(),
        ),
        pw.SizedBox(width: 20),
        // Totals (right side)
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                _totalRow(l10n.subtotal, currencyFormat.format(invoice.subtotal)),
                pw.Divider(height: 1, color: PdfColors.grey300),
                _totalRow('${l10n.totalTax} (${invoice.taxRate}%)', currencyFormat.format(taxAmount)),
                pw.Divider(height: 1, color: PdfColors.grey300),
                _totalRow(l10n.discount, '- ${currencyFormat.format(invoice.discountAmount)}'),
                pw.Divider(color: PdfColors.blueGrey800, height: 2),
                _totalRow(l10n.total.toUpperCase(), currencyFormat.format(invoice.total),
                  isBold: true, bg: PdfColors.blueGrey800, fg: PdfColors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool isBold = false, PdfColor? bg, PdfColor fg = PdfColors.black}) {
    final style = pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null, fontSize: isBold ? 13 : 10, color: fg);
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Context context, AppLocalizations l10n) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(l10n.paymentTerms,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text(l10n.thankyou,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.Text('${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }
}
