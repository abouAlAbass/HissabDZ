import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hissab_dz/core/widgets/sticky_action_footer.dart';
import 'package:hissab_dz/features/articles/domain/entities/article.dart';
import 'package:hissab_dz/features/articles/presentation/providers/article_providers.dart';
import 'package:hissab_dz/features/clients/domain/entities/client.dart';
import 'package:hissab_dz/features/clients/presentation/providers/client_providers.dart';
import 'package:hissab_dz/features/projects/presentation/providers/project_providers.dart';
import 'package:hissab_dz/features/quotes/data/repositories/quote_repository.dart';
import 'package:hissab_dz/features/quotes/domain/entities/quote.dart';
import 'package:hissab_dz/features/quotes/domain/entities/quote_item.dart';
import 'package:hissab_dz/features/quotes/domain/entities/quote_status.dart';
import 'package:hissab_dz/features/quotes/presentation/providers/quote_providers.dart';
import 'package:hissab_dz/features/quotes/presentation/widgets/quote_status_label.dart';
import 'package:hissab_dz/l10n/app_localizations.dart';

class CreateQuoteScreen extends ConsumerStatefulWidget {
  final int? quoteId;
  final int? initialProjectId;

  const CreateQuoteScreen({super.key, this.quoteId, this.initialProjectId});

  @override
  ConsumerState<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends ConsumerState<CreateQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quoteNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _approvalController = TextEditingController();
  final List<_LineControllers> _lines = [_LineControllers()];

  Client? _selectedClient;
  int? _selectedProjectId;
  DateTime _issueDate = DateTime.now();
  DateTime? _validUntil;
  QuoteStatus _status = QuoteStatus.draft;
  double _taxRate = 0;
  double _discount = 0;
  bool _isSaving = false;
  bool _isLoading = false;
  int? _draftQuoteId;
  Timer? _draftTimer;

  bool get _isEditMode => widget.quoteId != null;

  @override
  void initState() {
    super.initState();
    _validUntil = DateTime.now().add(const Duration(days: 30));
    _quoteNumberController.text =
        'DEV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _loadNextNumber();
    if (widget.initialProjectId != null) {
      _selectedProjectId = widget.initialProjectId;
    }
    if (_isEditMode) _loadQuote();
  }

  Future<void> _loadNextNumber() async {
    if (_isEditMode) return;
    final number = await ref
        .read(quoteRepositoryProvider)
        .generateNextQuoteNumber();
    if (!mounted) return;
    _quoteNumberController.text = number;
  }

  Future<void> _loadQuote() async {
    setState(() => _isLoading = true);
    final quote = await ref
        .read(quoteRepositoryProvider)
        .getQuoteById(widget.quoteId!);
    if (!mounted) return;
    if (quote == null) {
      context.pop();
      return;
    }

    for (final line in _lines) {
      line.dispose();
    }
    _lines
      ..clear()
      ..addAll(
        quote.items.map(
          (item) => _LineControllers(
            description: item.description,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          ),
        ),
      );
    if (_lines.isEmpty) _lines.add(_LineControllers());

    setState(() {
      _selectedClient = quote.client;
      _selectedProjectId = quote.projectId;
      _quoteNumberController.text = quote.quoteNumber;
      _notesController.text = quote.notes ?? '';
      _approvalController.text = quote.approvalName ?? '';
      _issueDate = quote.issueDate;
      _validUntil = quote.validUntil;
      _status = quote.status;
      _taxRate = quote.taxRate;
      _discount = quote.discountAmount;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _quoteNumberController.dispose();
    _notesController.dispose();
    _approvalController.dispose();
    _draftTimer?.cancel();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _subtotal => _lines.fold(0, (sum, line) {
    final quantity = double.tryParse(line.quantity.text) ?? 0;
    final price = double.tryParse(line.unitPrice.text) ?? 0;
    return sum + quantity * price;
  });

  double get _total => _subtotal + (_subtotal * _taxRate / 100) - _discount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clientsAsync = ref.watch(clientsListProvider);
    final projectsAsync = ref.watch(projectsListProvider);
    final articlesAsync = ref.watch(articlesListProvider);
    final isEditing = widget.quoteId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editQuote : l10n.createQuote),
      ),
      bottomNavigationBar: _isLoading
          ? null
          : StickyActionFooter(
              label: l10n.total,
              value: NumberFormat.currency(
                symbol: l10n.currencySymbol,
              ).format(_total),
              actionLabel: l10n.save,
              actionIcon: Icons.save_outlined,
              onPressed: _save,
              loading: _isSaving,
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _quoteNumberController,
                    decoration: InputDecoration(
                      labelText: l10n.quoteNumber,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? l10n.requiredField
                        : null,
                    onChanged: (_) => _scheduleDraftSave(),
                  ),
                  const SizedBox(height: 12),
                  clientsAsync.when(
                    data: (clients) => DropdownButtonFormField<Client>(
                      initialValue: _selectedClient,
                      decoration: InputDecoration(
                        labelText: l10n.selectClient,
                        border: const OutlineInputBorder(),
                      ),
                      items: clients
                          .map(
                            (client) => DropdownMenuItem(
                              value: client,
                              child: Text(client.name),
                            ),
                          )
                          .toList(),
                      onChanged: (client) => setState(() {
                        _selectedClient = client;
                        _selectedProjectId = null;
                        _scheduleDraftSave();
                      }),
                      validator: (value) =>
                          value == null ? l10n.requiredField : null,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, st) => Text('${l10n.error}: $e'),
                  ),
                  const SizedBox(height: 12),
                  projectsAsync.when(
                    data: (projects) {
                      final filtered = projects
                          .where(
                            (project) =>
                                _selectedClient == null ||
                                project.clientId == null ||
                                project.clientId == _selectedClient!.id,
                          )
                          .toList();
                      return DropdownButtonFormField<int?>(
                        initialValue: _selectedProjectId,
                        decoration: InputDecoration(
                          labelText: l10n.optionalProject,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(l10n.noProject),
                          ),
                          ...filtered.map(
                            (project) => DropdownMenuItem<int?>(
                              value: project.id,
                              child: Text(project.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _selectedProjectId = value;
                          _scheduleDraftSave();
                        }),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => Text('${l10n.error}: $e'),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusSelector(l10n),
                  const SizedBox(height: 16),
                  _buildTemplates(l10n, articlesAsync),
                  const SizedBox(height: 16),
                  Text(
                    l10n.items,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    _lines.length,
                    (index) => _buildLine(l10n, index),
                  ),
                  OutlinedButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addItem),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _taxRate.toStringAsFixed(0),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.tax,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {
                      _taxRate = double.tryParse(value) ?? 0;
                      _scheduleDraftSave();
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _discount.toStringAsFixed(0),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.discount,
                      prefixText: '${l10n.currencySymbol} ',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {
                      _discount = double.tryParse(value) ?? 0;
                      _scheduleDraftSave();
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.notesOptional,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _scheduleDraftSave(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _approvalController,
                    decoration: InputDecoration(
                      labelText: l10n.approvalSignature,
                      helperText: l10n.goodForApproval,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _scheduleDraftSave(),
                  ),
                  const SizedBox(height: 16),
                  _buildSummary(l10n),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(l10n.save),
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusSelector(AppLocalizations l10n) {
    return DropdownButtonFormField<QuoteStatus>(
      initialValue: _status,
      decoration: InputDecoration(
        labelText: l10n.status,
        border: const OutlineInputBorder(),
      ),
      items: QuoteStatus.values
          .where((status) => status != QuoteStatus.converted)
          .map(
            (status) => DropdownMenuItem(
              value: status,
              child: Text(quoteStatusText(l10n, status)),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() {
        _status = value ?? QuoteStatus.draft;
        _scheduleDraftSave();
      }),
    );
  }

  Widget _buildTemplates(
    AppLocalizations l10n,
    AsyncValue<List<Article>> articlesAsync,
  ) {
    final fallbackTemplates = {
      'painting': [
        (l10n.description, l10n.surfacePreparation, 1.0, 3500.0),
        (l10n.description, l10n.plasterAndSanding, 1.0, 4500.0),
        (l10n.description, l10n.paintingLabor, 1.0, 9000.0),
      ],
      'plumbing': [
        (l10n.description, l10n.travelCategory, 1.0, 1500.0),
        (l10n.description, l10n.leakDiagnosis, 1.0, 2500.0),
        (l10n.description, l10n.plumbingInstallation, 1.0, 6000.0),
      ],
      'electrical': [
        (l10n.description, l10n.travelCategory, 1.0, 1500.0),
        (l10n.description, l10n.wiringProtection, 1.0, 6500.0),
        (l10n.description, l10n.electricalLabor, 1.0, 7000.0),
      ],
      'masonry': [
        (l10n.description, l10n.masonryPreparation, 1.0, 3000.0),
        (l10n.description, l10n.blockWork, 1.0, 12000.0),
        (l10n.description, l10n.masonryLabor, 1.0, 8000.0),
      ],
    };
    final templateLabels = {
      'painting': l10n.paintingRoom,
      'plumbing': l10n.plumbingRepair,
      'electrical': l10n.electricalJob,
      'masonry': l10n.masonryWork,
    };
    final templateIcons = {
      'painting': Icons.format_paint_outlined,
      'plumbing': Icons.plumbing_outlined,
      'electrical': Icons.electrical_services_outlined,
      'masonry': Icons.construction_outlined,
    };
    final articles = articlesAsync.value ?? const <Article>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.quickTemplates,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: () => context.pushNamed('articles'),
              icon: const Icon(Icons.tune_outlined, size: 18),
              label: Text(l10n.configureQuickArticles),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: templateLabels.entries.map((entry) {
            final configuredRows = _configuredTemplateRows(entry.key, articles);
            final rows = configuredRows.isNotEmpty
                ? configuredRows
                : fallbackTemplates[entry.key]!;
            return ActionChip(
              label: Text(entry.value),
              avatar: Icon(templateIcons[entry.key], size: 18),
              onPressed: () => _applyTemplate(rows),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<(String, String, double, double)> _configuredTemplateRows(
    String template,
    List<Article> articles,
  ) {
    final matching =
        articles.where((article) => article.quickTemplate == template).toList()
          ..sort((a, b) {
            final order = a.quickTemplateOrder.compareTo(b.quickTemplateOrder);
            return order != 0 ? order : a.name.compareTo(b.name);
          });

    return matching.map((article) {
      final description = article.code == null || article.code!.isEmpty
          ? article.name
          : '${article.code} - ${article.name}';
      return (
        article.category,
        description,
        article.defaultQuantity,
        article.price,
      );
    }).toList();
  }

  Widget _buildLine(AppLocalizations l10n, int index) {
    final line = _lines[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.description,
                    decoration: InputDecoration(
                      labelText: l10n.description,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? l10n.requiredField
                        : null,
                    onChanged: (_) => _scheduleDraftSave(),
                  ),
                ),
                IconButton(
                  onPressed: _lines.length == 1
                      ? null
                      : () => _removeLine(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.quantity,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {
                      _scheduleDraftSave();
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: line.unitPrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.unitPrice,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {
                      _scheduleDraftSave();
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow(l10n.subtotal, _subtotal, l10n),
            _summaryRow(l10n.totalTax, _subtotal * _taxRate / 100, l10n),
            _summaryRow(l10n.discount, -_discount, l10n),
            const Divider(),
            _summaryRow(l10n.total, _total, l10n, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double value,
    AppLocalizations l10n, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${value.toStringAsFixed(2)} ${l10n.currencySymbol}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              fontSize: isTotal ? 18 : null,
            ),
          ),
        ],
      ),
    );
  }

  void _addLine() => setState(() => _lines.add(_LineControllers()));

  void _removeLine(int index) {
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  void _applyTemplate(List<(String, String, double, double)> rows) {
    setState(() {
      for (final line in _lines) {
        line.dispose();
      }
      _lines
        ..clear()
        ..addAll(
          rows.map(
            (row) => _LineControllers(
              description: row.$2,
              quantity: row.$3,
              unitPrice: row.$4,
            ),
          ),
        );
      _scheduleDraftSave();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedClient == null) return;
    setState(() => _isSaving = true);
    _draftTimer?.cancel();

    final quote = _buildQuote(id: widget.quoteId ?? _draftQuoteId);
    if (quote == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      if (_isEditMode || _draftQuoteId != null) {
        await ref.read(quoteRepositoryProvider).updateQuote(quote);
      } else {
        await ref.read(quoteRepositoryProvider).createQuote(quote);
      }
      ref.invalidate(quotesListProvider);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Quote? _buildQuote({int? id}) {
    if (_selectedClient?.id == null) return null;
    final items = _lines.map((line) {
      final quantity = double.tryParse(line.quantity.text) ?? 0;
      final price = double.tryParse(line.unitPrice.text) ?? 0;
      return QuoteItem(
        quoteId: id ?? 0,
        description: line.description.text.trim(),
        quantity: quantity,
        unitPrice: price,
        amount: quantity * price,
      );
    }).toList();

    final approvalName = _approvalController.text.trim();
    return Quote(
      id: id,
      clientId: _selectedClient!.id!,
      projectId: _selectedProjectId,
      quoteNumber: _quoteNumberController.text.trim(),
      status: _status,
      issueDate: _issueDate,
      validUntil: _validUntil,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      approvalName: approvalName.isEmpty ? null : approvalName,
      approvedAt: approvalName.isEmpty ? null : DateTime.now(),
      subtotal: _subtotal,
      taxRate: _taxRate,
      discountAmount: _discount,
      total: _total,
      items: items,
    );
  }

  void _scheduleDraftSave() {
    if (_isEditMode || _isLoading || _isSaving || _selectedClient?.id == null) {
      return;
    }
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(seconds: 2), _autoSaveDraft);
  }

  Future<void> _autoSaveDraft() async {
    if (!mounted || _selectedClient?.id == null) return;
    final quote = _buildQuote(id: _draftQuoteId);
    if (quote == null) return;
    final hasContent =
        quote.items.any((item) => item.description.trim().isNotEmpty) ||
        (quote.notes?.isNotEmpty ?? false) ||
        quote.total > 0;
    if (!hasContent) return;

    if (_draftQuoteId == null) {
      _draftQuoteId = await ref
          .read(quoteRepositoryProvider)
          .createQuote(quote);
    } else {
      await ref.read(quoteRepositoryProvider).updateQuote(quote);
    }
    ref.invalidate(quotesListProvider);
  }
}

class _LineControllers {
  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unitPrice;

  _LineControllers({
    String description = '',
    double quantity = 1,
    double unitPrice = 0,
  }) : description = TextEditingController(text: description),
       quantity = TextEditingController(text: quantity.toString()),
       unitPrice = TextEditingController(text: unitPrice.toStringAsFixed(2));

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}
