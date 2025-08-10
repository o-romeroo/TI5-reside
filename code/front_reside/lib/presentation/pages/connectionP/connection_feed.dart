import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front_reside/domain/services/feed_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:front_reside/presentation/controllers/user_profile_controller.dart';
import 'package:intl/intl.dart';
import 'package:front_reside/utils/api_config.dart';
import '../../widgets/interactive_post_card.dart';
import '../../widgets/add_post_dialog.dart';


class ConnectionFeed extends StatefulWidget {
  const ConnectionFeed({super.key});

  @override
  State<ConnectionFeed> createState() => _ConnectionFeedState();
}

class _ConnectionFeedState extends State<ConnectionFeed> {
  String _selectedFilter = 'Todos';
  List<Map<String, dynamic>> _allPosts = [];
  List<Map<String, dynamic>> _displayedPosts = [];
  bool _isLoadingFeed = true;
  String? _feedError;

  final FeedService _feedService = FeedService();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null).then((_) {
        _fetchFeedMessages();
    });
  }

  Future<void> _fetchFeedMessages() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFeed = true;
      _feedError = null;
    });

    try {
      final userProfile = Provider.of<UserProfileController>(context, listen: false);
      final residentId = userProfile.userId;

      if (residentId == null || residentId.isEmpty) {
        throw Exception("ID do residente não encontrado para buscar mensagens.");
      }

      final List<Map<String, dynamic>> fetchedMessages = await _feedService.getResidentMessages(residentId: residentId);
      
      if (!mounted) return;

      _allPosts = fetchedMessages.map((msg) {
        String? imageUrl;
        if (msg['has_image'] == true && msg['id'] != null) {
          imageUrl = "${ApiConfig.baseUrl}/messages/${msg['id']}/image";
        }
        
        Map<String, dynamic>? sender = msg['sender'] as Map<String, dynamic>?;
        String senderFirstName = sender?['first_name'] ?? 'Desconhecido';
        String senderLastNameInitial = (sender?['last_name'] as String?)?.isNotEmpty == true ? "${sender!['last_name'][0]}." : "";
        
        String userAvatar = msg['profile_picture_url_sender'] as String? ?? 'assets/avatar.png';
        if (userAvatar.isEmpty || !userAvatar.startsWith('http')) {
          userAvatar = 'assets/avatar.png'; 
        }

        return {
          'id': msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'senderId': msg['sender_id']?.toString(),
          'userName': '$senderFirstName $senderLastNameInitial'.trim(),
          'userAvatar': userAvatar,
          'createdAt': msg['created_at'] ?? DateTime.now().toIso8601String(),
          'content': msg['content'] ?? '',
          'imageUrl': imageUrl,
          'uploadedImageBytes': null,
          'isLiked': msg['is_liked_by_current_user'] ?? false, 
          'isSaved': msg['is_saved_by_current_user'] ?? false, 
        };
      }).toList();

      _allPosts.sort((a, b) {
        DateTime dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1900);
        DateTime dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });

      _applyFilter();

    } catch (e) {
      if (!mounted) return;
        print("Erro ao buscar mensagens do feed: $e");
      setState(() {
        _feedError = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingFeed = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'Salvos') {
      _displayedPosts = _allPosts.where((post) => post['isSaved'] == true).toList();
    } else {
      _displayedPosts = List.from(_allPosts);
    }
    if (mounted) {
      setState(() {});
    }
  }

  String _formatTimeAgo(String? isoDateString) {
    if (isoDateString == null) return 'agora';
    try {
      final date = DateTime.parse(isoDateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 5) {
        return 'agora';
      } else if (difference.inSeconds < 60) {
        return '${difference.inSeconds}s';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else if (difference.inDays < 365) {
        return DateFormat('dd MMM', 'pt_BR').format(date);
      } else {
        return DateFormat('dd/MM/yy', 'pt_BR').format(date);
      }
    } catch (e) {
      return 'data inv.';
    }
  }

  void _openAddPostDialog() async {
    final dynamic newPostDataFromDialog = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AddPostDialog();
      },
    );

    if (newPostDataFromDialog != null && newPostDataFromDialog is Map<String, dynamic>) {
      final userProfile = Provider.of<UserProfileController>(context, listen: false);
      String? newImageUrl;
      if (newPostDataFromDialog['has_image'] == true && newPostDataFromDialog['id'] != null) {
          newImageUrl = "${ApiConfig.baseUrl}/messages/${newPostDataFromDialog['id']}/image";
      }

      final newPost = {
        'id': newPostDataFromDialog['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': newPostDataFromDialog['senderId']?.toString() ?? userProfile.userId,
        'userName': "${userProfile.firstName ?? 'Usuário'} ${userProfile.lastName?.isNotEmpty == true ? userProfile.lastName![0] : ''}${userProfile.lastName?.isNotEmpty == true ? '.' : ''}",
        'userAvatar': userProfile.photoUrl ?? 'assets/avatar.png', 
        'createdAt': newPostDataFromDialog['createdAt'] ?? DateTime.now().toIso8601String(),
        'content': newPostDataFromDialog['content'],
        'imageUrl': newImageUrl, 
        'uploadedImageBytes': newPostDataFromDialog['uploadedImageBytes'],
        'isLiked': false,
        'isSaved': false,
      };
      
      setState(() {
        _allPosts.insert(0, newPost);
        _applyFilter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text("Todos", style: TextStyle(fontSize: 13)),
                  selected: _selectedFilter == 'Todos',
                  onSelected: (selected) {
                    _selectedFilter = 'Todos';
                    _applyFilter();
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.blue[50],
                  checkmarkColor: Colors.blue[700],
                  labelStyle: TextStyle(
                      color: _selectedFilter == 'Todos' ? Colors.blue[800] : Colors.black54,
                      fontWeight: _selectedFilter == 'Todos' ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: StadiumBorder(side: BorderSide(color: _selectedFilter == 'Todos' ? Colors.blue[200]! : Colors.grey[300]!)),
                ),
                FilterChip(
                  label: const Text("Salvos", style: TextStyle(fontSize: 13)),
                  selected: _selectedFilter == 'Salvos',
                  onSelected: (selected) {
                     _selectedFilter = 'Salvos';
                     _applyFilter();
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.blue[50],
                  checkmarkColor: Colors.blue[700],
                  labelStyle: TextStyle(
                      color: _selectedFilter == 'Salvos' ? Colors.blue[800] : Colors.black54,
                      fontWeight: _selectedFilter == 'Salvos' ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: StadiumBorder(side: BorderSide(color: _selectedFilter == 'Salvos' ? Colors.blue[200]! : Colors.grey[300]!)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingFeed
                ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
                : _feedError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 60),
                              const SizedBox(height: 16),
                              Text(
                                'Oops! Algo deu errado.',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _feedError!,
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh_rounded, size: 20),
                                label: const Text('Tentar Novamente'),
                                onPressed: _fetchFeedMessages,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    : _displayedPosts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.feed_outlined, color: Colors.grey[400], size: 70),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedFilter == 'Salvos'
                                    ? 'Você ainda não salvou nenhum post.'
                                    : 'Nenhum post no feed ainda.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 17, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                  ),
                                  if (_selectedFilter != 'Salvos')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Seja o primeiro a compartilhar algo com a comunidade!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchFeedMessages,
                            color: Colors.blue[700],
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(0, 4.0, 0, 80.0),
                              itemCount: _displayedPosts.length,
                              itemBuilder: (context, index) {
                                final post = _displayedPosts[index];
                                return InteractivePostCard(
                                  key: ValueKey(post['id']),
                                  userName: post['userName'] ?? 'Usuário Anônimo',
                                  timeAgo: _formatTimeAgo(post['createdAt'] as String?),
                                  description: post['content'] ?? '',
                                  userAvatar: post['userAvatar'] ?? 'assets/avatar.png',
                                  postImage: post['imageUrl'] ?? '',
                                  uploadedImageBytes: post['uploadedImageBytes'] as Uint8List?,
                                  isLiked: post['isLiked'] as bool? ?? false,
                                  isSaved: post['isSaved'] as bool? ?? false,
                                  onLikeToggle: () {
                                    setState(() {
                                      post['isLiked'] = !(post['isLiked'] as bool? ?? false);
                                    });
                                  },
                                  onSaveToggle: () {
                                    setState(() {
                                      post['isSaved'] = !(post['isSaved'] as bool? ?? false);
                                      _applyFilter();
                                    });
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPostDialog,
        tooltip: 'Adicionar Post',
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}