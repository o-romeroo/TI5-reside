import 'package:flutter/material.dart';

class HomePopup extends StatelessWidget {
  final String type;

  const HomePopup(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(type),
      content: SizedBox(
        // Definindo um tamanho fixo ou um tamanho máximo para o conteúdo do pop-up
        width: 300, // Largura do pop-up
        height: 200, // Altura do pop-up se necessário
        child: _buildPopupContent(),
      ),
      actions: [
        TextButton(
          child: Text('Fechar'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildPopupContent() {
    switch (type) {
      case 'Encomendas':
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text('Item 1')),
            ListTile(title: Text('Item 2')),
            ListTile(title: Text('Item 3')),
          ],
        );
      case 'Situação':
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text('Multa 1')),
          ],
        );
      case 'Condomínio':
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text('Boleto 1')),
          ],
        );
      default:
        return Text('Sem informações.');
    }
  }
}