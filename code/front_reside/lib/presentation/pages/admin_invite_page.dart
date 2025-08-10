import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/admin_invite_controller.dart';

class AdminInvitePage extends StatefulWidget {
  const AdminInvitePage({Key? key}) : super(key: key);
  @override
  State<AdminInvitePage> createState() => _AdminInvitePageState();
}

class _AdminInvitePageState extends State<AdminInvitePage> {
  final _formKey = GlobalKey<FormState>();
  late AdminInviteController _controller;
  bool _isLoading = false;

  // Lista dinâmica de pares email + apartamento
  final List<_InviteField> _fields = [];

  @override
  void initState() {
    super.initState();
    _controller = AdminInviteController();
    _addField();
  }

  @override
  void dispose() {
    for (var f in _fields) {
      f.emailController.dispose();
      f.apartmentController.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() {
      _fields.add(
        _InviteField(
          emailController: TextEditingController(),
          apartmentController: TextEditingController(),
        ),
      );
    });
  }

  void _removeField(int index) {
    setState(() {
      _fields[index].emailController.dispose();
      _fields[index].apartmentController.dispose();
      _fields.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final emails = _fields.map((f) => f.emailController.text.trim()).toList();
      final apartments =
          _fields.map((f) => f.apartmentController.text.trim()).toList();
      await _controller.sendInvites(emails, apartments);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convites enviados com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar convites: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Convidar Moradores')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _fields.length,
                  itemBuilder: (context, index) => _buildFieldBlock(index),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addField,
                  ),
                  const Text('Adicionar email/apartamento'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Enviar Convites'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldBlock(int index) {
    final field = _fields[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Convite #${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_fields.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeField(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: field.emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [
                FilteringTextInputFormatter.deny(
                  RegExp(r"\s"),
                ), // Bloqueia espaços
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe um e-mail.';
                }
                // Regex simples de validação de e-mail
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Informe um e-mail válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: field.apartmentController,
              decoration: const InputDecoration(labelText: 'Apartamento'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                FilteringTextInputFormatter.deny(
                  RegExp(r"\s"),
                ), // Bloqueia espaços
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o número do apartamento.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Classe auxiliar para manter controllers
class _InviteField {
  final TextEditingController emailController;
  final TextEditingController apartmentController;
  _InviteField({
    required this.emailController,
    required this.apartmentController,
  });
}
