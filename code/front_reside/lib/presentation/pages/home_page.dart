import 'package:flutter/material.dart';
import 'package:front_reside/presentation/cubits/user_profile_cubit.dart';
import 'package:intl/intl.dart';
import '../widgets/home_action_card.dart';
import '../widgets/home_header.dart';
import '../widgets/vagas_popup.dart';
import '../../presentation/pages/requests_page.dart';

class HomePageContent extends StatelessWidget {
  final UserProfileLoaded profileState;
  const HomePageContent({super.key, required this.profileState});

  void _showVagasPopup(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (_) => VagasPopup(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          HomeHeader(profileState: profileState),
          HomeActionCard(
            title: 'Ocorrências',
            subtitle: 'Ver e registrar ocorrências',
            date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
            buttonText: 'Acessar',
            icon: Icons.error_outline,
            onTap: () {
              final userRole = profileState.userRole;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestsPage(userRole: userRole),
                ),
              );
            },
          ),
          HomeActionCard(
            title: 'Vagas Contratadas',
            subtitle: 'Veja as vagas que você contratou',
            date: '',
            buttonText: 'Ver vagas contratadas',
            icon: Icons.directions_car,
            onTap: () => _showVagasPopup(context, 'minhas_vagas'),
          ),
          HomeActionCard(
            title: 'Vagas Ofertadas',
            subtitle: 'Veja as vagas do seu ap. e quem alugou',
            date: '',
            buttonText: 'Ver vagas ofertadas',
            icon: Icons.local_parking,
            onTap: () => _showVagasPopup(context, 'vagas_ofertadas'),
          ),
        ],
      ),
    );
  }
}