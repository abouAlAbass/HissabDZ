import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:invoice_app/core/theme/theme.dart';
import 'package:invoice_app/features/invoices/presentation/providers/invoice_providers.dart';
import 'package:invoice_app/features/clients/presentation/providers/client_providers.dart';
import 'package:invoice_app/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_app/features/invoices/domain/entities/invoice_item.dart';
import 'package:invoice_app/features/invoices/domain/entities/invoice_status.dart';
import 'package:invoice_app/features/clients/domain/entities/client.dart';
import 'package:invoice_app/l10n/app_localizations.dart';
import 'package:invoice_app/features/articles/domain/entities/article.dart';
import 'package:invoice_app/features/articles/presentation/providers/article_providers.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
  Client? _selectedClient;
  final DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;

  final List<Map<String, dynamic>> _items = [
    {'code': '', 'description': '', 'quantity': 1.0, 'unitPrice': 0.0},
  ];
  final List<TextEditingController> _codeControllers = [TextEditingController()];
  final List<TextEditingController> _descControllers = [TextEditingController()];
  final List<TextEditingController> _qtyControllers = [TextEditingController(text: '1.0')];
  final List<TextEditingController> _priceControllers = [TextEditingController(text: '0.00')];

  double _taxRate = 0;
  double _discount = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _invoiceNumberController.text = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _dueDate = DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    for (var c in _codeControllers) { c.dispose(); }
    for (var c in _descControllers) { c.dispose(); }
    for (var c in _qtyControllers) { c.dispose(); }
    for (var c in _priceControllers) { c.dispose(); }
    _invoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add({'code': '', 'description': '', 'quantity': 1.0, 'unitPrice': 0.0});
      _codeControllers.add(TextEditingController());
      _descControllers.add(TextEditingController());
      _qtyControllers.add(TextEditingController(text: '1.0'));
      _priceControllers.add(TextEditingController(text: '0.00'));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
        _codeControllers[index].dispose();
        _codeControllers.removeAt(index);
        _descControllers[index].dispose();
        _descControllers.removeAt(index);
        _qtyControllers[index].dispose();
        _qtyControllers.removeAt(index);
        _priceControllers[index].dispose();
        _priceControllers.removeAt(index);
      });
    }
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) {
      final qty = item['quantity'] as double;
      final price = item['unitPrice'] as double;
      return sum + (qty * price);
    });
  }

  double get _total {
    final sub = _subtotal;
    final tax = sub * _taxRate / 100;
    return sub + tax - _discount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(articlesListProvider); 
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createInvoice),
        actions: [
          if (_isSaving)
            const Center(child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            TextButton(
              onPressed: _saveInvoice,
              child: Text(l10n.save.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(l10n.clients),
              _buildClientPicker(),
              const SizedBox(height: 20),

              _buildSectionHeader(l10n.invoiceDetails),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _invoiceNumberController,
                    decoration: InputDecoration(labelText: l10n.invoiceNumber, prefixIcon: const Icon(Icons.tag)),
                    validator: (v) => (v == null || v.isEmpty) ? l10n.noData : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildDueDatePicker()),
              ]),
              const SizedBox(height: 20),

              _buildItemsSection(l10n),
              const SizedBox(height: 20),

              _buildSectionHeader(l10n.summary),
              _buildSummary(l10n),
              const SizedBox(height: 20),

              _buildSectionHeader(l10n.notes),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: l10n.notes,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey)),
    );
  }

  Widget _buildClientPicker() {
    final l10n = AppLocalizations.of(context)!;
    final clientsAsync = ref.watch(clientsListProvider);
    return clientsAsync.when(
      data: (clients) {
        if (clients.isEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text(l10n.noClients),
              subtitle: const Text('Add a client first'),
            ),
          );
        }
        return DropdownButtonFormField<Client>(
          initialValue: _selectedClient,
          decoration: InputDecoration(
            labelText: l10n.selectClient,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          items: clients.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
          onChanged: (v) => setState(() => _selectedClient = v),
          validator: (v) => v == null ? l10n.noData : null,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
    );
  }

  Widget _buildDueDatePicker() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: l10n.dueDate,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      controller: TextEditingController(
        text: _dueDate != null ? DateFormat.yMMMd().format(_dueDate!) : '',
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (date != null) setState(() => _dueDate = date);
      },
    );
  }

  Widget _buildItemsSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.items, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: Text(l10n.addItem),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FixedColumnWidth(90),
                2: FlexColumnWidth(2),
                3: FixedColumnWidth(60),
                4: FixedColumnWidth(100),
                5: FixedColumnWidth(90),
                6: FixedColumnWidth(40),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  children: [
                    const SizedBox(),
                    _tableHeader(l10n.code),
                    _tableHeader(l10n.description),
                    _tableHeader(l10n.quantity),
                    _tableHeader(l10n.price),
                    _tableHeader(l10n.amount, textAlign: TextAlign.right),
                    const SizedBox(),
                  ],
                ),
                ...List.generate(_items.length, (i) => _buildTableRow(i, l10n)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String label, {TextAlign textAlign = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.textSecondary.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        textAlign: textAlign,
      ),
    );
  }

  TableRow _buildTableRow(int i, AppLocalizations l10n) {
    final qty = double.tryParse(_qtyControllers[i].text) ?? 0;
    final price = double.tryParse(_priceControllers[i].text) ?? 0;
    final amount = qty * price;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: IconButton(
            icon: const Icon(Icons.inventory_2_rounded, size: 20, color: AppTheme.primaryIndigo),
            onPressed: () => _showArticlePicker(i),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: TextFormField(
            controller: _codeControllers[i],
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => setState(() => _items[i]['code'] = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: TextFormField(
            controller: _descControllers[i],
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => setState(() => _items[i]['description'] = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: TextFormField(
            controller: _qtyControllers[i],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => setState(() => _items[i]['quantity'] = double.tryParse(v) ?? 0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: TextFormField(
            controller: _priceControllers[i],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              prefixText: l10n.currencySymbol == 'دج' ? null : '${l10n.currencySymbol} ',
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => setState(() => _items[i]['unitPrice'] = double.tryParse(v) ?? 0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            NumberFormat.currency(symbol: l10n.currencySymbol).format(amount),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusOverdue, size: 20),
            onPressed: _items.length > 1 ? () => _removeItem(i) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(AppLocalizations l10n) {
    final taxAmount = _subtotal * _taxRate / 100;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryLine(l10n.subtotal, _subtotal, l10n),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(l10n.tax)),
              SizedBox(
                width: 60,
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true, suffixText: '%'),
                  initialValue: _taxRate.toString(),
                  onChanged: (v) => setState(() => _taxRate = double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Text(NumberFormat.currency(symbol: l10n.currencySymbol).format(taxAmount)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(l10n.discount)),
              SizedBox(
                width: 100,
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(isDense: true, prefixText: '${l10n.currencySymbol} '),
                  initialValue: _discount.toString(),
                  onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                ),
              ),
            ]),
            const Divider(height: 32),
            _summaryLine(l10n.total, _total, l10n, isBold: true, fontSize: 18, color: AppTheme.primaryIndigo),
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(String label, double value, AppLocalizations l10n, {bool isBold = false, double fontSize = 14, Color? color}) {
    final style = TextStyle(fontWeight: isBold ? FontWeight.bold : null, fontSize: fontSize, color: color);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(NumberFormat.currency(symbol: l10n.currencySymbol).format(value), style: style),
      ],
    );
  }

  void _showArticlePicker(int itemIndex) async {
    final l10n = AppLocalizations.of(context)!;
    final articles = ref.read(articlesListProvider).value ?? [];
    
    if (articles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noArticles)));
      return;
    }

    final article = await showModalBottomSheet<Article>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.articles, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: articles.length,
                itemBuilder: (ctx, idx) {
                  final a = articles[idx];
                  return ListTile(
                    leading: Icon(
                      a.type == 'physical' ? Icons.inventory_2 : Icons.build_circle,
                      color: AppTheme.primaryIndigo,
                    ),
                    title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(a.code ?? ''),
                    trailing: Text(NumberFormat.currency(symbol: l10n.currencySymbol).format(a.price)),
                    onTap: () => Navigator.pop(ctx, a),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (article != null) {
      setState(() {
        _items[itemIndex]['code'] = article.code ?? '';
        _items[itemIndex]['description'] = article.name;
        _items[itemIndex]['unitPrice'] = article.price;
        
        _codeControllers[itemIndex].text = article.code ?? '';
        _descControllers[itemIndex].text = article.name;
        _priceControllers[itemIndex].text = article.price.toStringAsFixed(2);
      });
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a client')));
      return;
    }
    if (_total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one item with a price')));
      return;
    }

    setState(() => _isSaving = true);

    final invoiceItems = List.generate(_items.length, (i) {
      final qty = (double.tryParse(_qtyControllers[i].text) ?? 0);
      final price = (double.tryParse(_priceControllers[i].text) ?? 0);
      final code = _codeControllers[i].text.trim();
      final desc = _descControllers[i].text.trim();
      
      return InvoiceItem(
        invoiceId: 0,
        description: code.isEmpty ? desc : '[$code] $desc',
        quantity: qty,
        unitPrice: price,
        amount: qty * price,
      );
    });

    final invoice = Invoice(
      clientId: _selectedClient!.id!,
      invoiceNumber: _invoiceNumberController.text,
      status: InvoiceStatus.draft,
      issueDate: _issueDate,
      dueDate: _dueDate,
      subtotal: _subtotal,
      taxRate: _taxRate,
      discountAmount: _discount,
      total: _total,
      items: invoiceItems,
      notes: _notesController.text,
    );

    try {
      await ref.read(invoiceRepositoryProvider).createInvoice(invoice);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice saved successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving invoice: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
