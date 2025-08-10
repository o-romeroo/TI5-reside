import 'package:flutter/material.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  BottomNavigationBarWidget({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.people, color: selectedIndex == 0 ? Colors.blue : Colors.grey),
          label: 'Conexão',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat, color: selectedIndex == 1 ? Colors.blue : Colors.grey),
          label: 'ChatBot',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home, color: selectedIndex == 2 ? Colors.blue : Colors.grey),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event, color: selectedIndex == 3 ? Colors.blue : Colors.grey),
          label: 'Eventos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_parking, color: selectedIndex == 4 ? Colors.blue : Colors.grey),
          label: 'Park',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: onItemTapped,
      showUnselectedLabels: true,
    );
  }
}