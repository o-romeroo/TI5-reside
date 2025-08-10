import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../application/use_cases/get_amenities_use_case.dart';
import '../../domain/entities/amenity_entity.dart';
import '../../infrastructure/data_sources/amenity_api_data_source.dart';
import '../../infrastructure/repositories/amenity_repository_impl.dart';
import '../cubits/amenities_cubit.dart';
import '../cubits/amenities_state.dart';

import 'create_booking_page.dart';

class AmenitiesPage extends StatelessWidget {
  const AmenitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final client = http.Client();
        final dataSource = AmenityApiDataSource(client: client);
        final repository = AmenityRepositoryImpl(dataSource: dataSource);
        final useCase = GetAmenitiesUseCase(repository);
        return AmenitiesCubit(getAmenitiesUseCase: useCase)..fetchAmenities();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reservar Área Comum'),
        ),
        body: BlocBuilder<AmenitiesCubit, AmenitiesState>(
          builder: (context, state) {
            if (state is AmenitiesLoading || state is AmenitiesInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AmenitiesLoaded) {
              if (state.amenities.isEmpty) {
                return const Center(
                  child: Text('Nenhuma área comum disponível no momento.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: state.amenities.length,
                itemBuilder: (context, index) {
                  final amenity = state.amenities[index];
                  return _AmenityCard(amenity: amenity);
                },
              );
            } else if (state is AmenitiesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Erro ao carregar áreas: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AmenitiesCubit>().fetchAmenities();
                      },
                      child: const Text('Tentar Novamente'),
                    )
                  ],
                ),
              );
            }
            return const Center(child: Text('Estado desconhecido.'));
          },
        ),
      ),
    );
  }
}

class _AmenityCard extends StatelessWidget {
  final AmenityEntity amenity;

  const _AmenityCard({required this.amenity});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      child: InkWell(
        onTap: () async {
          final bool? bookingWasCreated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateBookingPage(
                amenityId: amenity.id.toString(),
                amenityName: amenity.name,
              ),
            ),
          );

          if (bookingWasCreated == true && context.mounted) {
            Navigator.of(context).pop(true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amenity.name,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                amenity.description,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  const Icon(Icons.people, size: 16.0, color: Colors.grey),
                  const SizedBox(width: 4.0),
                  Text('Capacidade: ${amenity.capacity} pessoas'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}