import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../application/use_cases/create_request_use_case.dart';
import '../../infrastructure/data_sources/request_api_data_source.dart';
import '../../infrastructure/repositories/request_repository_impl.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({super.key});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedType;
  bool _isLoading = false;

  final List<String> _requestTypes = ['Reclamação', 'Sugestão', 'Manutenção', 'Outros'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final client = http.Client();
      final dataSource = RequestApiDataSource(client: client);
      final repository = RequestRepositoryImpl(dataSource: dataSource);
      final useCase = CreateRequestUseCase(repository);

      await useCase(
        title: _titleController.text,
        type: _selectedType!,
        description: _descriptionController.text,
      );

      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ocorrência registrada! Você será notificado sobre a resposta.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Ocorrência')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Título é obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                hint: const Text('Selecione um tipo'),
                items: _requestTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (v) => v == null ? 'Selecione um tipo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder(), alignLabelWithHint: true),
                maxLines: 5,
                validator: (v) => (v == null || v.isEmpty) ? 'Descrição é obrigatória' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Registrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}