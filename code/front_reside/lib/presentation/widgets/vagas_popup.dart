import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:front_reside/infrastructure/models/home_park_model.dart';
import 'package:front_reside/domain/services/home_park_service.dart';
import 'package:front_reside/presentation/controllers/user_profile_controller.dart';

class VagasPopup extends StatefulWidget {
  final String type; 
  const VagasPopup({super.key, required this.type});

  @override
  State<VagasPopup> createState() => _VagasPopupState();
}

class _VagasPopupState extends State<VagasPopup> {
  late Future<List<HomePark>> _futureVagas;
  final HomeParkService _service = HomeParkService();
  bool _isLoadingDelete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVagas();
    });
  }

  void _loadVagas() {
    final userProfile = Provider.of<UserProfileController>(context, listen: false);
    final int residentId = int.tryParse(userProfile.userId ?? '0') ?? 0;
    
    if (residentId == 0 && userProfile.userId != null && userProfile.userId!.isNotEmpty) {
      // ignore: avoid_print
      print("Alerta: UserID do perfil (${userProfile.userId}) não pôde ser convertido para inteiro para buscar vagas.");
    }

    setState(() {
      _futureVagas = widget.type == 'minhas_vagas'
          ? _service.getReservedParkings(residentId)
          : _service.getOfferedParkings(residentId);
    });
  }

  Future<void> _deleteParking(int parkingId) async {
    if(_isLoadingDelete) return;
    setState(() => _isLoadingDelete = true);
    try {
      await _service.deleteParking(parkingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga apagada com sucesso!'), backgroundColor: Colors.green),
        );
        _loadVagas();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao apagar a vaga: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingDelete = false);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString; 
    }
  }

   String _formatTime(String? timeString) {
    if (timeString == null) return 'N/A';
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final time = TimeOfDay(hour: hour, minute: minute);
        return time.format(context);
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.type == 'minhas_vagas' ? 'Vagas Contratadas' : 'Vagas Ofertadas'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        child: FutureBuilder<List<HomePark>>(
          future: _futureVagas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: theme.primaryColor));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 48),
                      const SizedBox(height: 16),
                      Text('Erro ao carregar vagas:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Text('${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Tentar Novamente"),
                        onPressed: _loadVagas,
                        style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: theme.colorScheme.onPrimary)
                      )
                    ],
                  ),
                ),
              );
            }
            final vagas = snapshot.data ?? [];
            if (vagas.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_parking_outlined, color: Colors.blue[300], size: 60),
                      const SizedBox(height: 16),
                      Text(
                        widget.type == 'minhas_vagas'
                            ? 'Você ainda não alugou nenhuma vaga.'
                            : 'Você ainda não ofertou nenhuma vaga.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: vagas.length,
              itemBuilder: (context, index) {
                final vaga = vagas[index];
                bool isVagaOfertada = widget.type == 'vagas_ofertadas';

                String nomeProprietarioDisplay = vaga.ownerName ?? "Não informado";
                String apartamentoProprietarioDisplay = vaga.ownerDetails?.apartment ?? "";
                String contatoProprietarioDisplay = vaga.ownerDetails?.contactPhone ?? "";

                String nomeReservanteDisplay = vaga.reserverName ?? "Não informado";
                String apartamentoReservanteDisplay = vaga.reserverDetails?.apartment ?? "";
                String contatoReservanteDisplay = vaga.reserverDetails?.contactPhone ?? "";

                return Card(
                  elevation: 1.5,
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                vaga.location,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16.5, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVagaOfertada)
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red[600], size: 24),
                                  tooltip: 'Apagar vaga',
                                  onPressed: _isLoadingDelete ? null : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Confirmar Exclusão'),
                                        content: const Text(
                                            'Tem certeza que deseja apagar esta oferta de vaga? Esta ação não pode ser desfeita.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            child: Text('Apagar', style: TextStyle(color: Colors.red[700])),
                                          ),
                                        ],
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _deleteParking(vaga.id);
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Divider(height: 12, thickness: 0.7, color: Colors.grey[300]),
                        
                        if (isVagaOfertada) ...[
                          if (vaga.status == 'reservado' && (vaga.reserverId != null)) ...[
                            RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14, color: Colors.grey[800], height: 1.5),
                                children: [
                                  const TextSpan(text: 'Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                  TextSpan(text: 'Alugada para ', style: TextStyle(color: Colors.green[800])),
                                  TextSpan(
                                    text: nomeReservanteDisplay,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
                                  ),
                                  if (apartamentoReservanteDisplay.isNotEmpty)
                                    TextSpan(text: ' (Ap. $apartamentoReservanteDisplay)'),
                                ],
                              ),
                            ),

                            if (contatoReservanteDisplay.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13.5, color: Colors.grey[700], height: 1.5),
                                    children: [
                                      const WidgetSpan(child: Icon(Icons.phone_iphone_rounded, size: 15, color: Colors.grey)),
                                      const TextSpan(text: ' Contato: '),
                                      TextSpan(text: contatoReservanteDisplay, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                            
                          ] else if (vaga.status == 'disponivel')
                            RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14, height: 1.5),
                                children: [
                                  const TextSpan(text: 'Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                  TextSpan(text: 'Disponível', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          else
                            Text('Status: ${vaga.status}', style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
                        ] else ...[ 
                          RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14, color: Colors.grey[800], height: 1.5),
                              children: [
                                const TextSpan(text: 'Proprietário: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                TextSpan(
                                  text: nomeProprietarioDisplay,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (apartamentoProprietarioDisplay.isNotEmpty)
                                  TextSpan(text: ' (Ap. $apartamentoProprietarioDisplay)'),
                              ],
                            ),
                          ),
                          if (contatoProprietarioDisplay.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13.5, color: Colors.grey[700], height: 1.5),
                                    children: [
                                      const WidgetSpan(child: Icon(Icons.phone_iphone_rounded, size: 15, color: Colors.grey)),
                                      const TextSpan(text: ' Contato: '),
                                      TextSpan(text: contatoProprietarioDisplay, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                        const SizedBox(height: 4),
                        Text('Tipo: ${vaga.type == 'diario' ? 'Diária' : 'Mensal'}', style: TextStyle(fontSize: 13.5, color: Colors.grey[700], height: 1.5)),
                        Text('Preço: R\$ ${double.tryParse(vaga.price)?.toStringAsFixed(2) ?? vaga.price}', style: TextStyle(fontSize: 13.5, color: Colors.grey[700], height: 1.5)),
                        if (vaga.type == 'diario' && vaga.availableDate != null) ...[
                          Text('Data: ${_formatDate(vaga.availableDate)}', style: TextStyle(fontSize: 13.5, color: Colors.grey[700], height: 1.5)),
                          Text('Horário: ${_formatTime(vaga.startTime)} - ${_formatTime(vaga.endTime)}', style: TextStyle(fontSize: 13.5, color: Colors.grey[700], height: 1.5)),
                        ],
                        if (vaga.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Obs: ${vaga.description}', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey[600], height: 1.4)),
                        ]
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Fechar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}