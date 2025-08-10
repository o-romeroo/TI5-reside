import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // 1) Import
import 'package:front_reside/domain/services/resident_service.dart';
import 'package:front_reside/domain/services/notification_service.dart';
import 'dart:async';
import '../pages/login_page.dart';
import '../main_layout.dart';
import 'package:provider/provider.dart';
import '../controllers/user_profile_controller.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // 2) Definição do GoogleSignIn COM OS SCOPES
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'openid', 'profile'],
    serverClientId:
        '341154778546-97fn9njh6jeoo2pvpa9hct6golp7hq2d.apps.googleusercontent.com',
  );

  Widget? _child;
  late StreamSubscription<User?> _authSub;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _child = const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Só chama login se não tiver user logado
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _handleGoogleSignIn();
    }

    _authSub = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthStateChanged,
    );
  }

  /// Faz login no Google e empurra as credenciais pro Firebase
  Future<void> _handleGoogleSignIn() async {
    try {
      print('🚀 Iniciando processo de login no Google...');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Usuário cancelou
        print('❌ Login Google cancelado');
        setState(() => _child = const LoginPage());
        return;
      }

      print('✅ Conta Google obtida: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Não retornou tokens do Google.');
      }

      // Cria credencial para o Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Loga no Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
      print('✅ Login no Firebase concluído');
    } catch (e) {
      print('❌ Erro no GoogleSignIn: $e');
      setState(() => _child = const LoginPage());
    }
  }

  /// Callback do authStateChanges
  Future<void> _onAuthStateChanged(User? user) async {
    print('🔄 AuthStateChange: usuário = ${user?.email ?? 'null'}');

    if (_isProcessing) {
      print('⏸️ Já processando, ignorando...');
      return;
    }
    _isProcessing = true;

    try {
      if (user == null) {
        print('❌ Usuário não autenticado, mostrando LoginPage');
        setState(() => _child = const LoginPage());
        return;
      }

      print('✅ Usuário autenticado: ${user.email}');
      // tenta obter ID token com retry
      String? idToken;
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          print('🔑 Tentativa $attempt de obter ID token...');
          idToken = await user.getIdToken(true);
          print('✅ Token obtido');
          break;
        } catch (e) {
          print('❌ Tentativa $attempt falhou: $e');
          await Future.delayed(Duration(milliseconds: 300 * attempt));
        }
      }

      if (idToken == null) {
        print('❌ Não foi possível obter token após 3 tentativas');
        await FirebaseAuth.instance.signOut();
        setState(() => _child = const LoginPage());
        return;
      }

      // Chama seu serviço pra ver se o residente já existe
      print('🔍 Verificando se residente existe...');
      print('🔍 GoogleId: ${user.uid}');
      print('🔍 IdToken: ${idToken.substring(0, 20)}...');

      // Tenta obter FCM token de forma opcional
      String? fcmToken;
      try {
        fcmToken = await NotificationService.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          print('📱 FCM Token obtido com sucesso');
        } else {
          print('📱 FCM Token não disponível - funcionando sem notificações');
        }
      } catch (e) {
        print('⚠️ Erro ao obter FCM token (continuando sem notificações): $e');
        fcmToken = null;
      }

      final exists = await ResidentService().checkIfResidentExists(
        user.uid,
        idToken,
        fcmToken: fcmToken,
      );
      print('🔍 Resultado: exists = $exists');

      if (exists) {
        print('✅ Residente existe, mostrando MainLayout');
        try {
          await Provider.of<UserProfileController>(
            context,
            listen: false,
          ).loadUserProfile();
          print('✅ Perfil carregado com sucesso');
        } catch (profileError) {
          print('❌ Erro ao carregar perfil: $profileError');
          // Continua mesmo se der erro no carregamento do perfil
        }
        setState(() => _child = const MainLayout());
      } else {
        print('ℹ️ Residente não existe, navegando p/ InvitePage');
        // Garantimos que idToken não é null aqui, pois já verificamos antes
        final nonNullIdToken = idToken; // Remove nullable
        setState(
          () =>
              _child = _NavigateToInvite(
                googleId: user.uid,
                idToken: nonNullIdToken,
              ),
        );
      }
    } catch (e) {
      print('❌ Erro de autenticação: $e');
      setState(() => _child = const LoginPage());
    } finally {
      _isProcessing = false;
      print('✅ Processamento concluído');
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _child ??
        const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Widget auxiliar para navegar p/ InvitePage
class _NavigateToInvite extends StatefulWidget {
  final String googleId;
  final String idToken;

  const _NavigateToInvite({required this.googleId, required this.idToken});

  @override
  State<_NavigateToInvite> createState() => _NavigateToInviteState();
}

class _NavigateToInviteState extends State<_NavigateToInvite> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(
        '/invite',
        arguments: {'googleId': widget.googleId, 'idToken': widget.idToken},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Redirecionando para cadastro...'),
          ],
        ),
      ),
    );
  }
}
