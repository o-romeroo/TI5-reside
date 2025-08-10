import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:front_reside/domain/services/feed_service.dart';
import 'package:provider/provider.dart';
import 'package:front_reside/presentation/controllers/user_profile_controller.dart';


class AddPostDialog extends StatefulWidget {
  const AddPostDialog({super.key});

  @override
  State<AddPostDialog> createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {
  final _descriptionController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isPickingImage = false;
  bool _isPosting = false;

  final FeedService _feedService = FeedService();

  Future<void> _pickImage() async {
    if (_isPosting || _isPickingImage) return;

    setState(() => _isPickingImage = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, 
      );

      if (result != null && result.files.single.bytes != null) {
        String fileName = result.files.single.name;
        String fileExtension = fileName.split('.').last.toLowerCase();
         if (fileExtension == 'jpg' || fileExtension == 'jpeg' || fileExtension == 'png' || fileExtension == 'gif' || fileExtension == 'webp') {
            if (result.files.single.size > 5 * 1024 * 1024) { 
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("A imagem excede o limite de 5MB."),
                            backgroundColor: Colors.orange,
                        ),
                    );
                }
                return; 
            }
            setState(() {
                _selectedImageBytes = result.files.single.bytes;
                _selectedImageName = fileName;
            });
        } else {
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Formato de imagem inválido. Use JPG, PNG, GIF ou WEBP."),
                        backgroundColor: Colors.orange,
                    ),
                );
            }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Nenhuma imagem selecionada.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao selecionar imagem: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _submitPost() async {
    if (_isPosting || _isPickingImage) return;

    if (_descriptionController.text.trim().isEmpty && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Adicione uma descrição ou uma imagem.")),
      );
      return;
    }

    final userProfile = Provider.of<UserProfileController>(context, listen: false);
    final senderId = userProfile.userId;

    if (senderId == null || senderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Não foi possível identificar o usuário. Tente novamente.")),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final newPostDataFromApi = await _feedService.sendCondominiumMessage(
        senderId: senderId,
        content: _descriptionController.text.trim(),
        imageBytes: _selectedImageBytes,
        imageName: _selectedImageName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Post enviado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop({
          'id': newPostDataFromApi['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'senderId': newPostDataFromApi['senderId']?.toString() ?? senderId,
          'content': newPostDataFromApi['content'] ?? _descriptionController.text.trim(),
          'imageUrl': newPostDataFromApi['imageUrl'], 
          'createdAt': newPostDataFromApi['createdAt'] ?? DateTime.now().toIso8601String(),
          'uploadedImageBytes': _selectedImageBytes, 
          'has_image': _selectedImageBytes != null,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar post: ${e.toString().replaceFirst("Exception: ", "")}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool canInteract = !_isPosting && !_isPickingImage;
    final userProfile = Provider.of<UserProfileController>(context, listen: false);


    return PopScope(
      canPop: canInteract,
      onPopInvoked: (didPop) {
        if (!didPop && !canInteract) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Aguarde a operação atual ser concluída.")),
          );
        }
      },
      child: AlertDialog(
        title: Text(
          'Criar Novo Post',
          style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9, 
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'No que você está pensando, ${userProfile.firstName ?? "Residente"}?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[700]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: canInteract ? Colors.grey[50] : Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 4,
                  minLines: 2,
                  textInputAction: TextInputAction.newline,
                  enabled: canInteract,
                ),
                const SizedBox(height: 16),
                if (_selectedImageBytes != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 180, 
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                          image: DecorationImage(
                            image: MemoryImage(_selectedImageBytes!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (canInteract)
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedImageBytes = null;
                                _selectedImageName = null;
                              });
                            },
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black.withOpacity(0.6),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                    ],
                  )
                else if (_selectedImageName != null && _selectedImageBytes == null) 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                        "Falha ao carregar o preview da imagem: $_selectedImageName",
                        style: const TextStyle(color: Colors.orangeAccent)),
                  ),
                SizedBox(
                  height: 48,
                  child: _isPickingImage
                      ? Center(child: CircularProgressIndicator(strokeWidth: 3, color: Colors.blue[700]))
                      : OutlinedButton.icon(
                          icon: Icon(Icons.add_photo_alternate_outlined, color: Colors.blue[700]),
                          label: Text(
                            _selectedImageBytes == null ? 'Adicionar Imagem' : 'Trocar Imagem',
                            style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600),
                          ),
                          onPressed: canInteract ? _pickImage : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.blue[600]!, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            backgroundColor: canInteract ? Colors.white : Colors.grey[200],
                          ),
                        ),
                ),
                const SizedBox(height: 20), 
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        actions: <Widget>[
          TextButton(
            onPressed: canInteract ? () { Navigator.of(context).pop(); } : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(color: canInteract ? Colors.grey[800] : Colors.grey[500] , fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: _isPosting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.send_rounded, size: 20),
            label: Text(_isPosting ? 'Enviando' : 'Postar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            onPressed: canInteract ? _submitPost : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canInteract ? Colors.blue[700] : Colors.blue[300],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: canInteract ? 2 : 0,
            ),
          ),
        ],
      ),
    );
  }
}