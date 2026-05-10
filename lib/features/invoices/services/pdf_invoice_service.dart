import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/domain/entities/business_profile.dart';
import '../domain/entities/invoice.dart';
import '../domain/entities/invoice_status.dart';

class PdfInvoiceService {
  static const _ink = PdfColors.blueGrey900;
  static const _muted = PdfColors.blueGrey600;
  static const _line = PdfColors.blueGrey100;
  static const _soft = PdfColors.grey100;
  static const _accent = PdfColors.teal700;

  static Future<File> generateInvoicePdf({
    required Invoice invoice,
    BusinessProfile? profile,
    required AppLocalizations l10n,
  }) async {
    final isRtl = l10n.localeName == 'ar';
    final textDirection = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final notoRegular = await PdfGoogleFonts.notoSansRegular();
    final notoBold = await PdfGoogleFonts.notoSansBold();
    final arabicRegular = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();
    final currencyFormat = NumberFormat.currency(symbol: l10n.currencySymbol);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);

    pw.MemoryImage? logoImage;
    if (profile?.logoPath != null) {
      final logoFile = File(profile!.logoPath!);
      if (logoFile.existsSync()) {
        logoImage = pw.MemoryImage(await logoFile.readAsBytes());
      }
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: isRtl ? arabicRegular : notoRegular,
        bold: isRtl ? arabicBold : notoBold,
        fontFallback: isRtl
            ? [notoRegular, notoBold]
            : [arabicRegular, arabicBold],
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 34, vertical: 30),
        textDirection: textDirection,
        build: (context) => [
          _header(invoice, profile, logoImage, dateFormat, l10n, isRtl),
          pw.SizedBox(height: 16),
          _infoRow(invoice, dateFormat, l10n, isRtl),
          pw.SizedBox(height: 20),
          _itemsTable(invoice, currencyFormat, l10n, textDirection),
          pw.SizedBox(height: 18),
          _totals(invoice, currencyFormat, l10n, isRtl),
        ],
        footer: (context) => _footer(context, l10n, isRtl),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      p.join(output.path, 'invoice_${invoice.invoiceNumber}.pdf'),
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _header(
    Invoice invoice,
    BusinessProfile? profile,
    pw.MemoryImage? logo,
    DateFormat dateFormat,
    AppLocalizations l10n,
    bool isRtl,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: _ink,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: _ordered(isRtl, [
          pw.Expanded(
            flex: 6,
            child: _businessBlock(profile, logo, l10n, isRtl),
          ),
          pw.SizedBox(width: 18),
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: isRtl
                  ? pw.CrossAxisAlignment.start
                  : pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  _headline(l10n.invoiceLabel, isRtl),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 25,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  invoice.invoiceNumber,
                  style: const pw.TextStyle(
                    color: PdfColors.blueGrey100,
                    fontSize: 11,
                  ),
                ),
                pw.SizedBox(height: 10),
                _statusPill(invoice.status, l10n),
                pw.SizedBox(height: 10),
                _headerMeta(
                  l10n.issueDate,
                  dateFormat.format(invoice.issueDate),
                  isRtl,
                ),
                if (invoice.dueDate != null)
                  _headerMeta(
                    l10n.dueDate,
                    dateFormat.format(invoice.dueDate!),
                    isRtl,
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  static pw.Widget _businessBlock(
    BusinessProfile? profile,
    pw.MemoryImage? logo,
    AppLocalizations l10n,
    bool isRtl,
  ) {
    final profileName = profile?.companyName.trim();
    final companyName = profileName != null && profileName.isNotEmpty
        ? profileName
        : l10n.companyName;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _ordered(isRtl, [
        _logoMark(logo, companyName),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: isRtl
                ? pw.CrossAxisAlignment.end
                : pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                companyName,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              if (profile?.address != null && profile!.address!.isNotEmpty)
                _businessLine(profile.address!),
              if (profile?.phone != null && profile!.phone!.isNotEmpty)
                _businessLine(profile.phone!),
              if (profile?.email != null && profile!.email!.isNotEmpty)
                _businessLine(profile.email!),
              if (profile?.website != null && profile!.website!.isNotEmpty)
                _businessLine(profile.website!),
            ],
          ),
        ),
      ]),
    );
  }

  static pw.Widget _logoMark(pw.MemoryImage? logo, String companyName) {
    if (logo != null) {
      return pw.Container(
        width: 62,
        height: 62,
        padding: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Image(logo, fit: pw.BoxFit.contain),
      );
    }

    final letters = companyName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1))
        .join()
        .toUpperCase();

    return pw.Container(
      width: 62,
      height: 62,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          letters.isEmpty ? 'HD' : letters,
          style: pw.TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static pw.Widget _businessLine(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        value,
        style: const pw.TextStyle(color: PdfColors.blueGrey100, fontSize: 9),
      ),
    );
  }

  static pw.Widget _headerMeta(String label, String value, bool isRtl) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        mainAxisAlignment: isRtl
            ? pw.MainAxisAlignment.start
            : pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            '$label: ',
            style: const pw.TextStyle(
              color: PdfColors.blueGrey100,
              fontSize: 8.5,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(
    Invoice invoice,
    DateFormat dateFormat,
    AppLocalizations l10n,
    bool isRtl,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _ordered(isRtl, [
        pw.Expanded(
          flex: 6,
          child: _panel(
            title: l10n.billTo,
            child: pw.Column(
              crossAxisAlignment: isRtl
                  ? pw.CrossAxisAlignment.end
                  : pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  invoice.client?.name ?? l10n.unknownClient,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                if (invoice.client?.email != null)
                  _detailLine(invoice.client!.email!),
                if (invoice.client?.phone != null)
                  _detailLine(invoice.client!.phone!),
                if (invoice.client?.address != null)
                  _detailLine(invoice.client!.address!),
                if (invoice.projectName != null &&
                    invoice.projectName!.isNotEmpty)
                  _detailLine('${l10n.project}: ${invoice.projectName!}'),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          flex: 4,
          child: _panel(
            title: l10n.invoiceDetails,
            child: pw.Column(
              children: [
                _infoLine(l10n.invoiceNumber, invoice.invoiceNumber, isRtl),
                _thinDivider(),
                _infoLine(
                  l10n.issueDate,
                  dateFormat.format(invoice.issueDate),
                  isRtl,
                ),
                if (invoice.dueDate != null) ...[
                  _thinDivider(),
                  _infoLine(
                    l10n.dueDate,
                    dateFormat.format(invoice.dueDate!),
                    isRtl,
                  ),
                ],
                _thinDivider(),
                _infoLine(
                  l10n.status,
                  _invoiceStatus(invoice.status, l10n),
                  isRtl,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  static pw.Widget _panel({required String title, required pw.Widget child}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(13),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  static pw.Widget _detailLine(String value) {
    if (value.trim().isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        value,
        style: const pw.TextStyle(color: PdfColors.blueGrey700, fontSize: 9.5),
      ),
    );
  }

  static pw.Widget _infoLine(String label, String value, bool isRtl) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: _ordered(isRtl, [
          pw.Text(
            label,
            style: const pw.TextStyle(
              color: PdfColors.blueGrey600,
              fontSize: 9,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ]),
      ),
    );
  }

  static pw.Widget _itemsTable(
    Invoice invoice,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
    pw.TextDirection textDirection,
  ) {
    final rows = invoice.items.isEmpty
        ? [
            [l10n.noData, '', '', ''],
          ]
        : invoice.items.map((item) {
            return [
              item.description,
              _quantity(item.quantity),
              currencyFormat.format(item.unitPrice),
              currencyFormat.format(item.amount),
            ];
          }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.items),
        pw.TableHelper.fromTextArray(
          headers: [l10n.description, l10n.quantity, l10n.price, l10n.amount],
          data: rows,
          border: const pw.TableBorder(
            top: pw.BorderSide(color: _line, width: 0.8),
            bottom: pw.BorderSide(color: _line, width: 0.8),
            horizontalInside: pw.BorderSide(
              color: PdfColors.grey200,
              width: 0.5,
            ),
          ),
          headerDecoration: const pw.BoxDecoration(color: _ink),
          oddRowDecoration: const pw.BoxDecoration(color: _soft),
          headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(
            color: PdfColors.blueGrey800,
            fontSize: 9,
          ),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          headerPadding: const pw.EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          cellAlignment: pw.Alignment.centerLeft,
          cellAlignments: const {
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
          columnWidths: const {
            0: pw.FlexColumnWidth(5),
            1: pw.FlexColumnWidth(1.1),
            2: pw.FlexColumnWidth(1.8),
            3: pw.FlexColumnWidth(1.8),
          },
          tableDirection: textDirection,
          headerDirection: textDirection,
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Container(width: 4, height: 15, color: _accent),
          pw.SizedBox(width: 7),
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totals(
    Invoice invoice,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
    bool isRtl,
  ) {
    final taxAmount = invoice.subtotal * invoice.taxRate / 100;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _ordered(isRtl, [
        pw.Expanded(flex: 5, child: _notes(invoice.notes, l10n)),
        pw.SizedBox(width: 18),
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line, width: 0.8),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _totalRow(
                  l10n.subtotal,
                  currencyFormat.format(invoice.subtotal),
                  isRtl,
                ),
                _thinDivider(),
                _totalRow(
                  '${l10n.totalTax} (${_quantity(invoice.taxRate)}%)',
                  currencyFormat.format(taxAmount),
                  isRtl,
                ),
                _thinDivider(),
                _totalRow(
                  l10n.discount,
                  '- ${currencyFormat.format(invoice.discountAmount)}',
                  isRtl,
                ),
                _totalRow(
                  l10n.total,
                  currencyFormat.format(invoice.total),
                  isRtl,
                  isHighlighted: true,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  static pw.Widget _notes(String? notes, AppLocalizations l10n) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(13),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.notes,
            style: pw.TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          pw.Text(
            notes?.trim().isNotEmpty == true
                ? notes!.trim()
                : l10n.paymentTerms,
            style: const pw.TextStyle(
              color: PdfColors.blueGrey700,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value,
    bool isRtl, {
    bool isHighlighted = false,
  }) {
    final color = isHighlighted ? PdfColors.white : _ink;
    return pw.Container(
      color: isHighlighted ? _ink : PdfColors.white,
      padding: pw.EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isHighlighted ? 10 : 7,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: _ordered(isRtl, [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: color,
              fontSize: isHighlighted ? 12 : 9,
              fontWeight: isHighlighted ? pw.FontWeight.bold : null,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: color,
              fontSize: isHighlighted ? 13 : 9,
              fontWeight: isHighlighted ? pw.FontWeight.bold : null,
            ),
          ),
        ]),
      ),
    );
  }

  static pw.Widget _footer(
    pw.Context context,
    AppLocalizations l10n,
    bool isRtl,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: _ordered(isRtl, [
          pw.Text(
            l10n.thankyou,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ]),
      ),
    );
  }

  static pw.Widget _statusPill(InvoiceStatus status, AppLocalizations l10n) {
    final colors = _statusColors(status);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: colors.$1,
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Text(
        _invoiceStatus(status, l10n),
        style: pw.TextStyle(
          color: colors.$2,
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static (PdfColor, PdfColor) _statusColors(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return (PdfColors.green100, PdfColors.green800);
      case InvoiceStatus.sent:
        return (PdfColors.blue100, PdfColors.blue800);
      case InvoiceStatus.accepted:
        return (PdfColors.teal100, PdfColors.teal800);
      case InvoiceStatus.converted:
        return (PdfColors.indigo100, PdfColors.indigo800);
      case InvoiceStatus.overdue:
      case InvoiceStatus.unpaid:
        return (PdfColors.red100, PdfColors.red800);
      case InvoiceStatus.cancelled:
        return (PdfColors.grey300, PdfColors.grey800);
      case InvoiceStatus.draft:
        return (PdfColors.blueGrey100, PdfColors.blueGrey800);
    }
  }

  static String _invoiceStatus(InvoiceStatus status, AppLocalizations l10n) {
    switch (status) {
      case InvoiceStatus.draft:
        return l10n.draft;
      case InvoiceStatus.sent:
        return l10n.sent;
      case InvoiceStatus.accepted:
        return l10n.accepted;
      case InvoiceStatus.converted:
        return l10n.converted;
      case InvoiceStatus.paid:
        return l10n.paid;
      case InvoiceStatus.unpaid:
        return l10n.unpaid;
      case InvoiceStatus.cancelled:
        return l10n.cancelled;
      case InvoiceStatus.overdue:
        return l10n.overdue;
    }
  }

  static pw.Widget _thinDivider() {
    return pw.Container(height: 0.7, color: _line);
  }

  static String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  static String _headline(String value, bool isRtl) {
    return isRtl ? value : value.toUpperCase();
  }

  static List<pw.Widget> _ordered(bool isRtl, List<pw.Widget> children) {
    return isRtl ? children.reversed.toList() : children;
  }
}
