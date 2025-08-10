import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    serverClientId:
        '341154778546-97fn9njh6jeoo2pvpa9hct6golp7hq2d.apps.googleusercontent.com',
    signInOption: SignInOption.standard,
  );

  bool _loading = false;

  Future<void> _handleSignIn() async {
    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        // Login via popup para Web
        GoogleAuthProvider provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // Login tradicional para Android/iOS
        final account = await _googleSignIn.signIn();
        if (account != null) {
          final googleAuth = await account.authentication;
          if (googleAuth.accessToken != null && googleAuth.idToken != null) {
            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            await FirebaseAuth.instance.signInWithCredential(credential);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao logar: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child:
            _loading
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Autenticando...'),
                  ],
                )
                : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Reside App',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Botão de login Google maior e full-width
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: SignInButton(
                          Buttons.Google,
                          text: 'Entrar com o Google',
                          onPressed: _handleSignIn,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Exibe info do usuário autenticado (caso já esteja logado)
                      StreamBuilder<User?>(
                        stream: FirebaseAuth.instance.authStateChanges(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Usuário autenticado! ✅',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    snapshot.data!.email ??
                                        'Email não disponível',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const Text(
                            'Nenhum usuário autenticado',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        },
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
