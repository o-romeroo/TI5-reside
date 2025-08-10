import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:front_reside/domain/services/notification_service.dart';
import 'firebase_options.dart';
import 'presentation/pages/invite_page.dart';
import 'package:front_reside/presentation/widgets/auth_gate.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/main_layout.dart';
import 'package:provider/provider.dart';
import 'presentation/controllers/user_profile_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa as notificações de forma opcional
  try {
    await NotificationService.initialize();
    print('📱 Notificações inicializadas com sucesso');
  } catch (e) {
    print('⚠️ Falha ao inicializar notificações (continuando sem elas): $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const MaterialColor lightBluePrimary =
        MaterialColor(0xFFADD8E6, <int, Color>{
          50: Color(0xFFE3F2FD),
          100: Color(0xFFBBDEFB),
          200: Color(0xFF90CAF9),
          300: Color(0xFF64B5F6),
          400: Color(0xFF42A5F5),
          500: Color(0xFF2196F3),
          600: Color(0xFF1E88E5),
          700: Color(0xFF1976D2),
          800: Color(0xFF1565C0),
          900: Color(0xFF0D47A1),
        });
    final Color? darkerBlueAccent = Colors.blue[700];

    return MaterialApp(
      title: 'Reside App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: lightBluePrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: darkerBlueAccent ?? Colors.blue,
          primary: darkerBlueAccent,
          secondary: darkerBlueAccent,
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/invite': (_) => const InvitePage(),
        '/home': (_) => const MainLayout(),
      },
    );
  }
}
