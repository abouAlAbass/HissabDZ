import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/client_providers.dart';
import '../../domain/entities/client.dart';

class ClientDetailsScreen extends ConsumerWidget {
  final int clientId;
  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditClientSheet(context, ref, clientId),
          ),
        ],
      ),
      body: clientsAsync.when(
        data: (clients) {
          final client = clients.firstWhere((c) => c.id == clientId, orElse: () => throw Exception('Client not found'));
          return _buildBody(context, client);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Client client) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(client.name[0].toUpperCase(), 
                style: TextStyle(fontSize: 40, color: Theme.of(context).colorScheme.onPrimaryContainer)),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(context, [
            _buildInfoRow(context, Icons.person, 'Full Name', client.name),
            _buildInfoRow(context, Icons.email, 'Email Address', client.email ?? 'Not provided'),
            _buildInfoRow(context, Icons.phone, 'Phone Number', client.phone ?? 'Not provided'),
            _buildInfoRow(context, Icons.location_on, 'Address', client.address ?? 'Not provided'),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditClientSheet(BuildContext context, WidgetRef ref, int id) {
    final clients = ref.read(clientsListProvider).value ?? [];
    final client = clients.firstWhere((c) => c.id == id);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: EditClientForm(client: client),
      ),
    );
  }
}

class EditClientForm extends ConsumerStatefulWidget {
  final Client client;
  const EditClientForm({super.key, required this.client});

  @override
  ConsumerState<EditClientForm> createState() => _EditClientFormState();
}

class _EditClientFormState extends ConsumerState<EditClientForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _emailController = TextEditingController(text: widget.client.email);
    _phoneController = TextEditingController(text: widget.client.phone);
    _addressController = TextEditingController(text: widget.client.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Client', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final updatedClient = widget.client.copyWith(
                    name: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    address: _addressController.text,
                  );
                  final navigator = Navigator.of(context);
                  await ref.read(clientRepositoryProvider).updateClient(updatedClient);
                  if (!mounted) return;
                  navigator.pop();
                }
              },
              child: const Text('Update Client'),
            ),
          ],
        ),
      ),
    );
  }
}
