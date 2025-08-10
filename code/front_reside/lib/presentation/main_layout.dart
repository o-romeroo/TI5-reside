import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:front_reside/presentation/pages/chatbot_page.dart';
import 'package:front_reside/presentation/pages/connectionP/connection_page.dart';
import 'package:front_reside/presentation/pages/events_page.dart';
import 'package:front_reside/presentation/pages/home_page.dart';
import 'package:front_reside/presentation/pages/admin_invite_page.dart';
import 'package:front_reside/presentation/pages/Park/park_page.dart';
import 'package:front_reside/presentation/cubits/user_profile_cubit.dart';

// O MainLayout agora é um StatelessWidget que apenas provê o Cubit.
class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserProfileCubit()..loadUserProfile(),
      child: const _MainLayoutView(),
    );
  }
}

// _MainLayoutView é o StatefulWidget que contém a lógica da UI.
class _MainLayoutView extends StatefulWidget {
  const _MainLayoutView();

  @override
  State<_MainLayoutView> createState() => _MainLayoutViewState();
}

class _MainLayoutViewState extends State<_MainLayoutView> {
  int _selectedIndex = 2; // Inicia na Home
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  Future<void> _logout() async {
    // Mostra o dialog de loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Faz o logout dos serviços
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      // Fecha o dialog após logout
      if (mounted) Navigator.of(context).pop();

      // O AuthGate cuidará de redirecionar para a LoginPage
    } catch (e) {
      // Fecha o dialog em caso de erro
      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro no logout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos o BlocBuilder para reconstruir a UI com base no estado do perfil.
    return BlocBuilder<UserProfileCubit, UserProfileState>(
      builder: (context, state) {
        // Estado de Carregamento Inicial
        if (state is UserProfileLoading || state is UserProfileInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Estado de Erro
        if (state is UserProfileError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Erro ao carregar perfil: ${state.message}'),
              ),
            ),
          );
        }

        // Estado de Sucesso (Perfil Carregado)
        if (state is UserProfileLoaded) {
          final isAdmin = state.userRole == 'admin';

          final pages = <Widget>[
            const ConnectionPage(),
            const ChatbotPage(),
            // Passa o estado carregado para a HomePageContent
            HomePageContent(profileState: state),
            const EventsPage(),
            const ParkPage(),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Reside App'),
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminInvitePage(),
                          ),
                        ),
                    color: Colors.blue.shade600,
                  ),
                IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
              ],
            ),
            body: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: pages,
            ),

            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.wifi),
                  label: 'Conexão',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: 'ChatBot',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event),
                  label: 'Eventos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_parking),
                  label: 'Park',
                ),
              ],
            ),
          );
        }

        return const Scaffold(body: Center(child: Text('Estado desconhecido')));
      },
    );
  }
}
