import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../providers/settings_providers.dart';
import '../../domain/entities/business_profile.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  String? _logoPath;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _initFromProfile(BusinessProfile profile) {
    if (!_initialized) {
      _nameController.text = profile.companyName;
      _addressController.text = profile.address ?? '';
      _phoneController.text = profile.phone ?? '';
      _emailController.text = profile.email ?? '';
      _websiteController.text = profile.website ?? '';
      _logoPath = profile.logoPath;
      _initialized = true;
    }
  }

  Future<void> _pickLogo() async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    // Copy image to app Documents so the path persists
    final docsDir = await getApplicationDocumentsDirectory();
    final logoDir = Directory(p.join(docsDir.path, 'InvoicePro', 'logos'));
    if (!logoDir.existsSync()) logoDir.createSync(recursive: true);

    final ext = p.extension(file.path);
    final savedPath = p.join(logoDir.path, 'company_logo$ext');
    await File(file.path).copy(savedPath);

    setState(() => _logoPath = savedPath);
  }

  void _removeLogo() => setState(() => _logoPath = null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(businessProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appSettings)),
      body: profileAsync.when(
        data: (profile) {
          if (profile != null) _initFromProfile(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo Section ──────────────────────────────────────────
                  Text('Company Logo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildLogoSection(context),
                  const SizedBox(height: 24),

                  // ── Business Info ─────────────────────────────────────────
                  Text(l10n.companyInfo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Text('Appears on all generated PDF invoices', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l10n.companyName, prefixIcon: const Icon(Icons.business)),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: l10n.address, prefixIcon: const Icon(Icons.location_on)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: l10n.phone, prefixIcon: const Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _websiteController,
                    decoration: InputDecoration(labelText: l10n.website, prefixIcon: const Icon(Icons.language)),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _save(l10n),
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(l10n.saveSettings),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    final hasLogo = _logoPath != null && File(_logoPath!).existsSync();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Logo preview
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasLogo
                  ? Image.file(File(_logoPath!), fit: BoxFit.contain)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 4),
                        Text('No Logo', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
            ),
            const SizedBox(width: 20),

            // Action buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickLogo,
                    icon: const Icon(Icons.upload_file),
                    label: Text(hasLogo ? 'Change Logo' : 'Upload Logo'),
                  ),
                  if (hasLogo) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _removeLogo,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Remove Logo', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'PNG or JPG, used on PDF invoices.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final profile = BusinessProfile(
      companyName: _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      logoPath: _logoPath,
    );

    await ref.read(settingsRepositoryProvider).saveBusinessProfile(profile);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsSaved), backgroundColor: Colors.green),
      );
    }
  }
}
