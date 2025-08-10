import 'package:flutter/material.dart';
import 'package:front_reside/presentation/cubits/user_profile_cubit.dart';

class HomeHeader extends StatelessWidget {
  final UserProfileLoaded profileState;

  const HomeHeader({
    super.key,
    required this.profileState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.fromARGB(255, 50, 216, 238),
            Color.fromARGB(255, 150, 74, 201),
            Color.fromARGB(255, 21, 206, 144),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${profileState.firstName} ${profileState.lastName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              profileState.photoUrl != null && profileState.photoUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(profileState.photoUrl!),
                      backgroundColor: Colors.transparent,
                    )
                  : const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 30, color: Colors.white),
                    ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profileState.condoName ?? 'Condomínio não informado',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Apto: ${profileState.apartment ?? 'N/A'}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}