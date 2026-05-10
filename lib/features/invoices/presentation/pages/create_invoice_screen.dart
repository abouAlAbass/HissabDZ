import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hissab_dz/core/theme/theme.dart';
import 'package:hissab_dz/core/widgets/sticky_action_footer.dart';
import 'package:hissab_dz/features/invoices/presentation/providers/invoice_providers.dart';
import 'package:hissab_dz/features/clients/presentation/providers/client_providers.dart';
import 'package:hissab_dz/features/invoices/domain/entities/invoice.dart';
import 'package:hissab_dz/features/invoices/domain/entities/invoice_item.dart';
import 'package:hissab_dz/features/invoices/domain/entities/invoice_status.dart';
import 'package:hissab_dz/features/clients/domain/entities/client.dart';
import 'package:hissab_dz/features/projects/domain/entities/project.dart';
import 'package:hissab_dz/features/projects/presentation/providers/project_providers.dart';
import 'package:hissab_dz/l10n/app_localizations.dart';
import 'package:hissab_dz/features/articles/domain/entities/article.dart';
import 'package:hissab_dz/features/articles/presentation/providers/article_providers.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final int? invoiceId;
  final int? initialProjectId;

  const CreateInvoiceScreen({super.key, this.invoiceId, this.initialProjectId});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();

  Client? _selectedClient;
  int? _selectedProjectId;
  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;
  InvoiceStatus _status = InvoiceStatus.draft;

  final List<Map<String, dynamic>> _items = [
    {'code': '', 'description': '', 'quantity': 1.0, 'unitPrice': 0.0},
  ];
  final List<TextEditingController> _codeControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _descControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _qtyControllers = [
    TextEditingController(text: '1.0'),
  ];
  final List<TextEditingController> _priceControllers = [
    TextEditingController(text: '0.00'),
  ];

  double _taxRate = 0;
  double _discount = 0;
  bool _isSaving = false;
  bool _isLoadingExistingInvoice = false;

  bool get _isEditMode => widget.invoiceId != null;

  @override
  void initState() {
    super.initState();
    _invoiceNumberController.text =
        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _dueDate = DateTime.now().add(const Duration(days: 30));
    if (widget.initialProjectId != null) {
      _loadInitialProject(widget.initialProjectId!);
    }
    if (_isEditMode) {
      _loadExistingInvoice();
    }
  }

  Future<void> _loadInitialProject(int projectId) async {
    final project = await ref
        .read(projectRepositoryProvider)
        .getProjectById(projectId);
    if (!mounted || project == null) return;
    final client = project.clientId == null
        ? null
        : await ref
              .read(clientRepositoryProvider)
              .getClientById(project.clientId!);
    if (!mounted) return;
    setState(() {
      _selectedProjectId = project.id;
      if (client != null) _selectedClient = client;
    });
  }

  Future<void> _loadExistingInvoice() async {
    setState(() => _isLoadingExistingInvoice = true);
    final invoice = await ref
        .read(invoiceRepositoryProvider)
        .getInvoiceById(widget.invoiceId!);
    if (!mounted) return;

    if (invoice == null) {
      setState(() => _isLoadingExistingInvoice = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noData)),
      );
      context.pop();
      return;
    }

    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final controller in _descControllers) {
      controller.dispose();
    }
    for (final controller in _qtyControllers) {
      controller.dispose();
    }
    for (final controller in _priceControllers) {
      controller.dispose();
    }

    _items
      ..clear()
      ..addAll(
        invoice.items.map((item) {
          final parsed = _splitCodeAndDescription(item.description);
          return {
            'code': parsed.code,
            'description': parsed.description,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
          };
        }),
      );

    if (_items.isEmpty) {
      _items.add({
        'code': '',
        'description': '',
        'quantity': 1.0,
        'unitPrice': 0.0,
      });
    }

    _codeControllers
      ..clear()
      ..addAll(
        _items.map(
          (item) => TextEditingController(text: item['code'] as String),
        ),
      );
    _descControllers
      ..clear()
      ..addAll(
        _items.map(
          (item) => TextEditingController(text: item['description'] as String),
        ),
      );
    _qtyControllers
      ..clear()
      ..addAll(
        _items.map(
          (item) => TextEditingController(
            text: (item['quantity'] as double).toString(),
          ),
        ),
      );
    _priceControllers
      ..clear()
      ..addAll(
        _items.map(
          (item) => TextEditingController(
            text: (item['unitPrice'] as double).toStringAsFixed(2),
          ),
        ),
      );

    setState(() {
      _selectedClient = invoice.client;
      _selectedProjectId = invoice.projectId;
      _invoiceNumberController.text = invoice.invoiceNumber;
      _issueDate = invoice.issueDate;
      _dueDate = invoice.dueDate;
      _status = invoice.status;
      _taxRate = invoice.taxRate;
      _discount = invoice.discountAmount;
      _notesController.text = invoice.notes ?? '';
      _isLoadingExistingInvoice = false;
    });
  }

  @override
  void dispose() {
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var c in _descControllers) {
      c.dispose();
    }
    for (var c in _qtyControllers) {
      c.dispose();
    }
    for (var c in _priceControllers) {
      c.dispose();
    }
    _invoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add({
        'code': '',
        'description': '',
        'quantity': 1.0,
        'unitPrice': 0.0,
      });
      _codeControllers.add(TextEditingController());
      _descControllers.add(TextEditingController());
      _qtyControllers.add(TextEditingController(text: '1.0'));
      _priceControllers.add(TextEditingController(text: '0.00'));
    });
  }

  void _appendItemFromArticle(Article article) {
    final quantity = article.defaultQuantity <= 0
        ? 1.0
        : article.defaultQuantity;
    _items.add({
      'code': article.code ?? '',
      'description': article.name,
      'quantity': quantity,
      'unitPrice': article.price,
    });
    _codeControllers.add(TextEditingController(text: article.code ?? ''));
    _descControllers.add(TextEditingController(text: article.name));
    _qtyControllers.add(TextEditingController(text: quantity.toString()));
    _priceControllers.add(
      TextEditingController(text: article.price.toStringAsFixed(2)),
    );
  }

  bool _isItemEmpty(int index) {
    return _codeControllers[index].text.trim().isEmpty &&
        _descControllers[index].text.trim().isEmpty &&
        (double.tryParse(_priceControllers[index].text) ?? 0) == 0;
  }

  void _applyArticleToItem(int index, Article article) {
    final quantity = article.defaultQuantity <= 0
        ? 1.0
        : article.defaultQuantity;
    _items[index]['code'] = article.code ?? '';
    _items[index]['description'] = article.name;
    _items[index]['quantity'] = quantity;
    _items[index]['unitPrice'] = article.price;

    _codeControllers[index].text = article.code ?? '';
    _descControllers[index].text = article.name;
    _qtyControllers[index].text = quantity.toString();
    _priceControllers[index].text = article.price.toStringAsFixed(2);
  }

  void _addQuickTemplateArticles(
    String template,
    List<Article> articles,
    AppLocalizations l10n,
  ) {
    final matching =
        articles.where((article) => article.quickTemplate == template).toList()
          ..sort((a, b) {
            final order = a.quickTemplateOrder.compareTo(b.quickTemplateOrder);
            return order != 0 ? order : a.name.compareTo(b.name);
          });

    if (matching.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noQuickTemplateArticles)));
      return;
    }

    setState(() {
      var start = 0;
      if (_items.length == 1 && _isItemEmpty(0)) {
        _applyArticleToItem(0, matching.first);
        start = 1;
      }
      for (final article in matching.skip(start)) {
        _appendItemFromArticle(article);
      }
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
    final articlesAsync = ref.watch(articlesListProvider);

    if (_isLoadingExistingInvoice) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editInvoice)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editInvoice : l10n.createInvoice),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveInvoice,
              child: Text(
                l10n.save.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      bottomNavigationBar: StickyActionFooter(
        label: l10n.total,
        value: NumberFormat.currency(
          symbol: l10n.currencySymbol,
        ).format(_total),
        actionLabel: l10n.save,
        actionIcon: Icons.save_outlined,
        onPressed: _saveInvoice,
        loading: _isSaving,
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

              _buildSectionHeader(l10n.project),
              _buildProjectPicker(),
              const SizedBox(height: 20),

              _buildSectionHeader(l10n.invoiceDetails),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _invoiceNumberController,
                      decoration: InputDecoration(
                        labelText: l10n.invoiceNumber,
                        prefixIcon: const Icon(Icons.tag),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l10n.noData : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDueDatePicker()),
                ],
              ),
              const SizedBox(height: 20),

              _buildItemsSection(l10n, articlesAsync),
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
              const SizedBox(height: 112),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
              subtitle: Text(l10n.addClientFirst),
            ),
          );
        }
        return DropdownButtonFormField<Client>(
          initialValue: _selectedClient,
          decoration: InputDecoration(
            labelText: l10n.selectClient,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          items: clients
              .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedClient = v),
          validator: (v) => v == null ? l10n.noData : null,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, st) => Text('${l10n.error}: $e'),
    );
  }

  Widget _buildProjectPicker() {
    final l10n = AppLocalizations.of(context)!;
    final projectsAsync = ref.watch(projectsListProvider);
    return projectsAsync.when(
      data: (projects) {
        return DropdownButtonFormField<int?>(
          initialValue: _selectedProjectId,
          decoration: InputDecoration(
            labelText: l10n.optionalProject,
            prefixIcon: const Icon(Icons.folder_open),
          ),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(l10n.noProject)),
            ...projects.map(
              (project) => DropdownMenuItem<int?>(
                value: project.id,
                child: Text(project.name),
              ),
            ),
          ],
          onChanged: (value) => _selectProject(value, projects),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, st) => Text('${l10n.error}: $e'),
    );
  }

  Future<void> _selectProject(int? projectId, List<Project> projects) async {
    Project? project;
    if (projectId != null) {
      for (final candidate in projects) {
        if (candidate.id == projectId) {
          project = candidate;
          break;
        }
      }
    }
    Client? client;
    if (project?.clientId != null) {
      client = await ref
          .read(clientRepositoryProvider)
          .getClientById(project!.clientId!);
    }
    if (!mounted) return;
    setState(() {
      _selectedProjectId = projectId;
      if (client != null) _selectedClient = client;
    });
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

  Widget _buildItemsSection(
    AppLocalizations l10n,
    AsyncValue<List<Article>> articlesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuickTemplateActions(l10n, articlesAsync),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 650) {
              return _buildMobileItemsList(l10n);
            }
            return _buildDesktopItemsTable(l10n);
          },
        ),
      ],
    );
  }

  Widget _buildQuickTemplateActions(
    AppLocalizations l10n,
    AsyncValue<List<Article>> articlesAsync,
  ) {
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

    return articlesAsync.when(
      data: (articles) {
        final configured = articles
            .where((article) => article.quickTemplate != null)
            .toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.quickTemplates,
                        style: Theme.of(context).textTheme.titleMedium,
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
                if (configured.isEmpty)
                  Text(
                    l10n.noQuickTemplateArticles,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: templateLabels.entries.map((entry) {
                      final count = configured
                          .where(
                            (article) => article.quickTemplate == entry.key,
                          )
                          .length;
                      return ActionChip(
                        avatar: Icon(templateIcons[entry.key], size: 18),
                        label: Text('${entry.value} ($count)'),
                        onPressed: count == 0
                            ? null
                            : () => _addQuickTemplateArticles(
                                entry.key,
                                articles,
                                l10n,
                              ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, st) => Text('${l10n.error}: $e'),
    );
  }

  Widget _buildDesktopItemsTable(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.items,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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
                0: FixedColumnWidth(150),
                1: FixedColumnWidth(90),
                2: FlexColumnWidth(2),
                3: FixedColumnWidth(60),
                4: FixedColumnWidth(120),
                5: FixedColumnWidth(100),
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

  Widget _buildMobileItemsList(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.items,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: Text(l10n.addItem),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_items.length, (i) => _buildMobileItemCard(i, l10n)),
      ],
    );
  }

  Widget _buildMobileItemCard(int i, AppLocalizations l10n) {
    final qty = double.tryParse(_qtyControllers[i].text) ?? 0;
    final price = double.tryParse(_priceControllers[i].text) ?? 0;
    final amount = qty * price;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showArticlePicker(i),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: Text(l10n.chooseFromArticles),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.statusOverdue,
                  ),
                  onPressed: _items.length > 1 ? () => _removeItem(i) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codeControllers[i],
                    decoration: InputDecoration(
                      labelText: l10n.code,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) => setState(() => _items[i]['code'] = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descControllers[i],
              decoration: InputDecoration(
                labelText: l10n.description,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _items[i]['description'] = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtyControllers[i],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.quantity,
                      isDense: true,
                    ),
                    onChanged: (v) => setState(
                      () => _items[i]['quantity'] = double.tryParse(v) ?? 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _priceControllers[i],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.price,
                      isDense: true,
                      prefixText: l10n.currencySymbol == 'دج'
                          ? null
                          : '${l10n.currencySymbol} ',
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (v) => setState(
                      () => _items[i]['unitPrice'] = double.tryParse(v) ?? 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.amount,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          symbol: l10n.currencySymbol,
                        ).format(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
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
          child: OutlinedButton.icon(
            onPressed: () => _showArticlePicker(i),
            icon: const Icon(Icons.inventory_2_outlined, size: 16),
            label: Text(
              l10n.chooseFromArticles,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 40),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: TextFormField(
            controller: _codeControllers[i],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => setState(() => _items[i]['code'] = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: TextFormField(
            controller: _descControllers[i],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => setState(() => _items[i]['description'] = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: TextFormField(
            controller: _qtyControllers[i],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) =>
                setState(() => _items[i]['quantity'] = double.tryParse(v) ?? 0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: TextFormField(
            controller: _priceControllers[i],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              prefixText: l10n.currencySymbol == 'دج'
                  ? null
                  : '${l10n.currencySymbol} ',
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            onChanged: (v) => setState(
              () => _items[i]['unitPrice'] = double.tryParse(v) ?? 0,
            ),
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
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.statusOverdue,
              size: 20,
            ),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.tax,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      suffixText: '%',
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    initialValue: _taxRate.toString(),
                    onChanged: (v) =>
                        setState(() => _taxRate = double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  NumberFormat.currency(
                    symbol: l10n.currencySymbol,
                  ).format(taxAmount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.discount,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixText: l10n.currencySymbol == 'دج'
                          ? null
                          : '${l10n.currencySymbol} ',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.statusOverdue,
                    ),
                    initialValue: _discount.toString(),
                    onChanged: (v) =>
                        setState(() => _discount = double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _summaryLine(
              l10n.total,
              _total,
              l10n,
              isBold: true,
              fontSize: 18,
              color: AppTheme.primaryIndigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(
    String label,
    double amount,
    AppLocalizations l10n, {
    bool isBold = false,
    double fontSize = 15,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
        Text(
          NumberFormat.currency(symbol: l10n.currencySymbol).format(amount),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w700,
            fontSize: fontSize + 2,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showArticlePicker(int itemIndex) async {
    final l10n = AppLocalizations.of(context)!;
    final articles = ref.read(articlesListProvider).value ?? [];

    if (articles.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noArticles)));
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
              child: Text(
                l10n.articles,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: articles.length,
                itemBuilder: (ctx, idx) {
                  final a = articles[idx];
                  return ListTile(
                    leading: Icon(
                      a.type == 'physical'
                          ? Icons.inventory_2
                          : Icons.build_circle,
                      color: AppTheme.primaryIndigo,
                    ),
                    title: Text(
                      a.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(a.code ?? ''),
                    trailing: Text(
                      NumberFormat.currency(
                        symbol: l10n.currencySymbol,
                      ).format(a.price),
                    ),
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
        _applyArticleToItem(itemIndex, article);
      });
    }
  }

  Future<void> _saveInvoice() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectClient)));
      return;
    }
    if (_total <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addAtLeastOnePricedItem)));
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
      projectId: _selectedProjectId,
      invoiceNumber: _invoiceNumberController.text,
      status: _status,
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
      if (_isEditMode) {
        await ref
            .read(invoiceRepositoryProvider)
            .updateInvoice(invoice.copyWith(id: widget.invoiceId));
      } else {
        await ref.read(invoiceRepositoryProvider).createInvoice(invoice);
      }
      
      // Invalidate providers to refresh UI
      ref.invalidate(invoicesListProvider);
      ref.invalidate(filteredInvoicesProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invoiceSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorSavingInvoice}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ({String code, String description}) _splitCodeAndDescription(String value) {
    final match = RegExp(r'^\[(.+)\]\s*(.*)$').firstMatch(value);
    if (match == null) {
      return (code: '', description: value);
    }
    return (code: match.group(1) ?? '', description: match.group(2) ?? '');
  }
}
