// lib/presentation/pages/connectionP/widgets/interactive_post_card.dart
import 'package:flutter/material.dart';
import 'dart:typed_data'; // Para Uint8List

class InteractivePostCard extends StatefulWidget {
  final String userName;
  final String timeAgo;
  final String description;
  final String userAvatar;
  final String postImage; // URL da imagem de rede ou path do asset
  final Uint8List? uploadedImageBytes; // Para imagens recém-criadas antes de ter URL
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLikeToggle;
  final VoidCallback onSaveToggle;

  const InteractivePostCard({
    super.key,
    required this.userName,
    required this.timeAgo,
    required this.description,
    required this.userAvatar,
    required this.postImage,
    this.uploadedImageBytes,
    required this.isLiked,
    required this.isSaved,
    required this.onLikeToggle,
    required this.onSaveToggle,
  });

  @override
  State<InteractivePostCard> createState() => _InteractivePostCardState();
}

class _InteractivePostCardState extends State<InteractivePostCard> {
  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    bool hasDisplayableImage = false;

    if (widget.uploadedImageBytes != null) {
      hasDisplayableImage = true;
      imageWidget = Image.memory(
        widget.uploadedImageBytes!,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
      );
    } else if (widget.postImage.isNotEmpty) {
      hasDisplayableImage = true;
      if (widget.postImage.startsWith('http')) {
        imageWidget = Image.network(
          widget.postImage,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2.0,
                  color: Colors.blue[700],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print("Erro ao carregar imagem de rede: ${widget.postImage} - $error");
            return Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 50)),
            );
          }
        );
      } else { // Assume que é um asset local
        imageWidget = Image.asset(
          widget.postImage,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey[200],
            child: Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 50)),
          ),
        );
      }
    } else {
      imageWidget = const SizedBox.shrink(); // Não ocupa espaço se não houver imagem
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      elevation: 1.5,
      clipBehavior: Clip.antiAlias, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 8.0, 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300], // Cor de fundo enquanto carrega ou se falhar
                  backgroundImage: widget.userAvatar.startsWith('http')
                    ? NetworkImage(widget.userAvatar) as ImageProvider // Cast para ImageProvider
                    : AssetImage(widget.userAvatar),
                  onBackgroundImageError: widget.userAvatar.startsWith('http') 
                    ? (e, s) { print("Erro ao carregar avatar de rede: ${widget.userAvatar} - $e"); } 
                    : null, // Nenhuma ação de erro para AssetImage, ele lançará um erro se o asset não for encontrado
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      Text(
                        widget.timeAgo,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, color: Colors.grey[700]),
                  tooltip: "Opções",
                  onSelected: (String result) {
                    if (result == 'denunciar') {
                      // Idealmente, chame um método passado como callback para lidar com a denúncia
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post denunciado com sucesso! (Funcionalidade simulada)')),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'denunciar',
                      child: Row(children: [Icon(Icons.report_gmailerrorred_rounded, size: 20, color: Colors.red[700]), const SizedBox(width: 10), const Text('Denunciar')]),
                    ),
                    // Você pode adicionar mais opções aqui, como "Editar", "Excluir" (se for o dono do post)
                  ],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ],
            ),
          ),
          
          if (widget.description.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, hasDisplayableImage ? 8.0 : 12.0),
              child: Text(
                widget.description,
                style: TextStyle(color: Colors.grey[850], fontSize: 14.5, height: 1.45),
              ),
            ),

          if (hasDisplayableImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8.0), 
              child: imageWidget,
            ),
          
          Divider(height: 1, thickness: 0.5, color: Colors.grey[200], indent: 16, endIndent: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(
                    widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 23,
                  ),
                  color: widget.isLiked ? Colors.pinkAccent : Colors.grey[700],
                  onPressed: widget.onLikeToggle,
                  tooltip: widget.isLiked ? "Descurtir" : "Curtir",
                ),
                IconButton(
                  icon: Icon(
                    widget.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    size: 23,
                  ),
                  color: widget.isSaved ? Colors.blue[700] : Colors.grey[700],
                  onPressed: widget.onSaveToggle,
                  tooltip: widget.isSaved ? "Remover dos Salvos" : "Salvar",
                ),
                // Poderia adicionar um botão de comentário aqui
              ],
            ),
          ),
        ],
      ),
    );
  }
}