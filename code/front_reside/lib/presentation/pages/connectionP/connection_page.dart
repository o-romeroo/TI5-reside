import 'package:flutter/material.dart';
import 'connection_feed.dart';

class ConnectionPage extends StatelessWidget {
  const ConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Conexão',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: const ConnectionFeed(),
    );
  }
}