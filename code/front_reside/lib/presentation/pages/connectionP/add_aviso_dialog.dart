import 'package:flutter/material.dart';

class AddAvisoDialog extends StatefulWidget {

  final List<String> availableCategories;

  const AddAvisoDialog({super.key, required this.availableCategories});

  @override
  State<AddAvisoDialog> createState() => _AddAvisoDialogState();
}

class _AddAvisoDialogState extends State<AddAvisoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  String? _selectedCategory; 
  bool _isImportant = false;

  @override
  void initState() {
    super.initState();

    if (widget.availableCategories.isNotEmpty) {
      final firstCategory = widget.availableCategories.firstWhere(
        (cat) => cat != 'Todos',
        orElse: () => 'Geral', 
      );
      _selectedCategory = firstCategory;
    } else {
      _selectedCategory = 'Geral'; 
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final List<String> categoriesForDropdown =
        (widget.availableCategories.where((cat) => cat != 'Todos').toList()..add('Geral')).toSet().toList();
    categoriesForDropdown.sort(); 

    return AlertDialog(
      title: const Text('Novo Aviso'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título do Aviso'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(labelText: 'Descrição do Aviso'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição.';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: categoriesForDropdown.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(), 
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma categoria.';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: const Text('Marcar como importante'),
                value: _isImportant,
                onChanged: (bool value) {
                  setState(() {
                    _isImportant = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade de seleção de imagem (frontend)')),
                  );
                  
                },
                icon: const Icon(Icons.image),
                label: const Text('Adicionar Imagem (Opcional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newId = DateTime.now().millisecondsSinceEpoch.toString();
              final newAviso = {
                'id': newId,
                'title': _titleController.text,
                'subtitle': _subtitleController.text,
                'imageUrl': 'assets/default_aviso.png',
                'date': DateTime.now(), 
                'isImportant': _isImportant,
                'category': _selectedCategory ?? 'Geral', 
              };
              Navigator.pop(context, newAviso); 
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}