import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/entities/article.dart';

class PdfArticlePricesService {
  static const _ink = PdfColors.blueGrey900;
  static const _muted = PdfColors.blueGrey600;
  static const _line = PdfColors.blueGrey100;
  static const _soft = PdfColors.grey100;
  static const _accent = PdfColors.teal700;

  static Future<File> generateArticlePricesPdf({
    required List<Article> articles,
    required AppLocalizations l10n,
  }) async {
    final isRtl = l10n.localeName == 'ar';
    final textDirection = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final notoRegular = await PdfGoogleFonts.notoSansRegular();
    final notoBold = await PdfGoogleFonts.notoSansBold();

    pw.Font arabicRegular;
    pw.Font arabicBold;

    try {
      final arabicRegularData = await rootBundle.load(
        'assets/fonts/Amiri-Regular.ttf',
      );
      final arabicBoldData = await rootBundle.load(
        'assets/fonts/Amiri-Bold.ttf',
      );
      arabicRegular = pw.Font.ttf(arabicRegularData);
      arabicBold = pw.Font.ttf(arabicBoldData);
    } catch (_) {
      arabicRegular = await PdfGoogleFonts.amiriRegular();
      arabicBold = await PdfGoogleFonts.amiriBold();
    }

    final sortedArticles = [...articles]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
          _header(l10n, isRtl),
          pw.SizedBox(height: 18),
          _sectionTitle(l10n.articles, isRtl),
          _articlesTable(sortedArticles, l10n, isRtl),
        ],
        footer: (context) => _footer(context, l10n),
      ),
    );

    final output = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(output.path, 'article_prices_$timestamp.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _header(AppLocalizations l10n, bool isRtl) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: _ink,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _headline(l10n.articleSalePrices, isRtl),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            DateFormat.yMMMd(l10n.localeName).format(DateTime.now()),
            style: const pw.TextStyle(
              color: PdfColors.blueGrey100,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _articlesTable(
    List<Article> articles,
    AppLocalizations l10n,
    bool isRtl,
  ) {
    final headers = [l10n.code, l10n.description, l10n.unit, l10n.pricePerUnit];

    return pw.TableHelper.fromTextArray(
      headers: isRtl ? headers.reversed.toList() : headers,
      data: articles.map((article) {
        final row = [
          article.code?.trim().isNotEmpty == true ? article.code!.trim() : '-',
          article.name,
          article.unit,
          _formatCurrency(article.price, l10n, isRtl),
        ];
        return isRtl ? row.reversed.toList() : row;
      }).toList(),
      border: const pw.TableBorder(
        top: pw.BorderSide(color: _line, width: 0.8),
        bottom: pw.BorderSide(color: _line, width: 0.8),
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
      ),
      headerDecoration: const pw.BoxDecoration(color: _ink),
      oddRowDecoration: const pw.BoxDecoration(color: _soft),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(color: PdfColors.blueGrey800, fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      headerAlignment: pw.Alignment.center,
      cellAlignment: isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      cellAlignments: isRtl
          ? const {
              0: pw.Alignment.centerRight,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
            }
          : const {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
            },
      columnWidths: isRtl
          ? const {
              0: pw.FlexColumnWidth(1.8),
              1: pw.FlexColumnWidth(1.1),
              2: pw.FlexColumnWidth(4.6),
              3: pw.FlexColumnWidth(1.2),
            }
          : const {
              0: pw.FlexColumnWidth(1.2),
              1: pw.FlexColumnWidth(4.6),
              2: pw.FlexColumnWidth(1.1),
              3: pw.FlexColumnWidth(1.8),
            },
    );
  }

  static pw.Widget _sectionTitle(String title, bool isRtl) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: isRtl
            ? pw.MainAxisAlignment.end
            : pw.MainAxisAlignment.start,
        children: [
          if (!isRtl) pw.Container(width: 4, height: 15, color: _accent),
          if (!isRtl) pw.SizedBox(width: 7),
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (isRtl) pw.SizedBox(width: 7),
          if (isRtl) pw.Container(width: 4, height: 15, color: _accent),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context, AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            l10n.appTitle,
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
        ],
      ),
    );
  }

  static String _headline(String value, bool isRtl) {
    return isRtl ? value : value.toUpperCase();
  }

  static String _formatCurrency(
    double amount,
    AppLocalizations l10n,
    bool isRtl,
  ) {
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '');
    final formattedAmount = formatter.format(amount).trim();
    if (!isRtl) return '${l10n.currencySymbol} $formattedAmount';
    return '\u200F$formattedAmount ${l10n.currencySymbol}';
  }
}
