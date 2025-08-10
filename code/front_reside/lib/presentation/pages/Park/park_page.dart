import 'package:flutter/material.dart';
import 'offer_spot_page.dart'; 
import 'find_spot_page.dart';   

class ParkPage extends StatelessWidget {
  const ParkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text(
          'Aluguel de Vagas', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5, 
        centerTitle: true,
      ),
      body: Center( 
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              
              Text(
                'Bem-vindo ao sistema de vagas do condomínio!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Escolha uma opção abaixo para gerenciar ou encontrar vagas de estacionamento.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey[600],
                ),
              ),
              const SizedBox(height: 48), 

              
              Card(
                elevation: 4, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: InkWell( 
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OfferSpotPage()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        Icon(Icons.drive_eta, size: 50, color: Colors.blue[600]), 
                        const SizedBox(height: 12),
                        const Text(
                          "Disponibilizar Minha Vaga",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Ofereça sua vaga quando não estiver usando-a. Ajude a comunidade!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24), 

              Card(
                elevation: 4, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: InkWell( 
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FindSpotPage()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        Icon(Icons.local_parking, size: 50, color: Colors.blue[600]), 
                        const SizedBox(height: 12),
                        const Text(
                          "Procurar uma Vaga Disponível",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Encontre e reserve uma vaga rapidamente para o seu veículo.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}