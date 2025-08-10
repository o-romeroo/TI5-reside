import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogoutButton extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  LogoutButton({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Faz logout do Google
      // await _googleSignIn.signOut();
      // Faz logout do Firebase
      await FirebaseAuth.instance.signOut();

      print('✅ Logout realizado com sucesso');
      // Redireciona para a rota de login (use o nome que você definiu no MaterialApp)
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('❌ Erro ao fazer logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Sair'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _handleLogout(context),
    );
  }
}
