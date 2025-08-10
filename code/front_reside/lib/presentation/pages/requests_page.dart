import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:front_reside/application/use_cases/get_requests_use_case.dart';
import 'package:front_reside/application/use_cases/respond_to_request_use_case.dart';
import 'package:front_reside/domain/entities/request_entity.dart';
import 'package:front_reside/infrastructure/data_sources/request_api_data_source.dart';
import 'package:front_reside/infrastructure/repositories/request_repository_impl.dart';
import 'package:front_reside/presentation/cubits/requests_cubit.dart';
import 'package:front_reside/presentation/cubits/requests_state.dart';
import 'package:front_reside/presentation/cubits/respond_request_cubit.dart';
import 'package:front_reside/presentation/pages/create_request_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class RequestsPage extends StatefulWidget {
  final String userRole;
  const RequestsPage({super.key, required this.userRole});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.userRole == 'admin';

    return BlocProvider(
      create: (context) {
        final client = http.Client();
        final dataSource = RequestApiDataSource(client: client);
        final repository = RequestRepositoryImpl(dataSource: dataSource);
        final useCase = GetRequestsUseCase(repository);
        return RequestsCubit(useCase)..fetchRequests();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Ocorrências')),
        floatingActionButton: !isAdmin
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const CreateRequestPage()),
                  ).then((result) {
                    if (result == true) {
                      context.read<RequestsCubit>().fetchRequests();
                    }
                  });
                },
                child: const Icon(Icons.add),
              )
            : null,
        body: BlocConsumer<RequestsCubit, RequestsState>(
          listener: (context, state) {
            if (state is RequestsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is RequestsLoading || state is RequestsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is RequestsLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<RequestsCubit>().fetchRequests(),
                child: ListView(
                  padding: const EdgeInsets.all(8.0),
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        title: Text('Em Aberto (${state.openRequests.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        initiallyExpanded: true,
                        children: state.openRequests.isEmpty
                            ? [const ListTile(title: Text('Nenhuma ocorrência nesta categoria.', style: TextStyle(color: Colors.grey)))]
                            : state.openRequests.map((request) => _RequestTile(
                                  request: request,
                                  isAdmin: isAdmin,
                                  onResponded: () => context.read<RequestsCubit>().fetchRequests(),
                                )).toList(),
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        title: Text('Resolvidas (${state.closedRequests.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        initiallyExpanded: false,
                        children: state.closedRequests.isEmpty
                            ? [const ListTile(title: Text('Nenhuma ocorrência nesta categoria.', style: TextStyle(color: Colors.grey)))]
                            : state.closedRequests.map((request) => _RequestTile(
                                  request: request,
                                  isAdmin: isAdmin,
                                  onResponded: () => context.read<RequestsCubit>().fetchRequests(),
                                )).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('Nenhuma ocorrência para exibir.'));
          },
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final RequestEntity request;
  final bool isAdmin;
  final VoidCallback onResponded;

  const _RequestTile({required this.request, required this.isAdmin, required this.onResponded});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(request.title, overflow: TextOverflow.ellipsis),
      subtitle: Text('Criado por: ${request.creatorName}'),
      children: [_buildDetailsPanel(context)],
    );
  }

  String _formatDuration(DateTime start, DateTime? end) {
    final now = end ?? DateTime.now();
    final duration = now.difference(start);
    if (duration.inDays > 0) return '${duration.inDays}d atrás';
    if (duration.inHours > 0) return '${duration.inHours}h atrás';
    if (duration.inMinutes < 1) return 'agora mesmo';
    return '${duration.inMinutes}m atrás';
  }

  void _showRespondDialog(BuildContext pageContext) {
    final responseController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return BlocProvider(
          create: (context) {
            final client = http.Client();
            final dataSource = RequestApiDataSource(client: client);
            final repository = RequestRepositoryImpl(dataSource: dataSource);
            final useCase = RespondToRequestUseCase(repository);
            return RespondRequestCubit(useCase);
          },
          child: BlocConsumer<RespondRequestCubit, RespondRequestState>(
            listener: (context, state) {
              if (state is RespondRequestSuccess) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  const SnackBar(content: Text('Resposta enviada com sucesso!'), backgroundColor: Colors.green),
                );
                onResponded();
              }
              if (state is RespondRequestError) {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(content: Text('Erro ao responder: ${state.message}'), backgroundColor: Colors.red),
                );
              }
            },
            builder: (builderContext, state) {
              return AlertDialog(
                title: const Text('Responder Ocorrência'),
                content: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: responseController,
                    decoration: const InputDecoration(labelText: 'Sua resposta', border: OutlineInputBorder()),
                    maxLines: 4,
                    validator: (v) => (v == null || v.isEmpty) ? 'A resposta não pode ser vazia' : null,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: state is RespondRequestLoading ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
  
                  ElevatedButton(
                    onPressed: state is RespondRequestLoading ? null : () {
                      if (formKey.currentState!.validate()) {
                        builderContext.read<RespondRequestCubit>().respond(
                          id: request.id,
                          response: responseController.text,
                        );
                      }
                    },
                    child: state is RespondRequestLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Enviar Resposta'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailsPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Tipo:', request.type),
          _buildDetailRow('Status:', request.status == RequestStatus.open ? 'Em Aberto' : 'Resolvida'),
          if (request.status == RequestStatus.open)
            _buildDetailRow('Tempo em aberto:', _formatDuration(request.createdAt, null))
          else if (request.closedAt != null)
            _buildDetailRow('Fechada em:', DateFormat('dd/MM/yy HH:mm').format(request.closedAt!)),
          const Divider(height: 24),
          const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(request.description),
          if (request.status == RequestStatus.closed && request.response != null && request.response!.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Resposta do Síndico:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 4),
            Text(request.response!),
          ],
          if (isAdmin && request.status == RequestStatus.open) ...[
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showRespondDialog(context),
                child: const Text('Responder Ocorrência'),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, textAlign: TextAlign.end, overflow: TextOverflow.fade, softWrap: false)),
        ],
      ),
    );
  }
}