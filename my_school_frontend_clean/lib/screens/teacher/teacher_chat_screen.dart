import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_school_frontend/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TeacherChatScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  final String contactRole;
  final String teacherId;
  final String teacherName;
  final VoidCallback? onMessagesRead;

  const TeacherChatScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.contactRole,
    required this.teacherId,
    required this.teacherName,
    this.onMessagesRead,
  });

  @override
  State<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late IO.Socket _socket;
  bool _isLoading = true;
  bool _isConnected = false;
  List<Map<String, dynamic>> _attachedFiles = [];
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isDisposed = false;
  Map<String, dynamic>? _contactInfo;
  int _unreadCount = 0;
  bool _isSending = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initSocket();
    _loadMessages();
    _loadContactInfo();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _typingTimer?.cancel();
    _socket.off('new_message');
    _socket.off('message_sent');
    _socket.off('message_error');
    _socket.off('message_read');
    _socket.off('user_typing');
    _socket.off('authenticated');
    _socket.off('connect');
    _socket.off('disconnect');
    _socket.disconnect();
    _socket.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContactInfo() async {
    try {
      setState(() {
        _contactInfo = {
          'name': widget.contactName,
          'role': widget.contactRole,
          'avatar': widget.contactName.isNotEmpty ? widget.contactName.substring(0, 1).toUpperCase() : '?',
        };
      });
    } catch (e) {
      print('Erreur chargement contact info: $e');
    }
  }

  void _initSocket() {
    _socket = IO.io('http://10.0.2.2:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    _socket.on('connect', (_) {
      if (!_isDisposed && mounted) {
        print('🟢 Connecté au serveur WebSocket');
        _socket.emit('authenticate', widget.teacherId);
      }
    });

    _socket.on('authenticated', (data) {
      if (!_isDisposed && mounted) {
        print('✅ Authentifié sur le serveur WebSocket');
        if (mounted) {
          setState(() {
            _isConnected = true;
          });
        }
      }
    });

    _socket.on('new_message', (data) {
      if (!_isDisposed && mounted) {
        print('📨 Nouveau message reçu en temps réel');
        if (mounted) {
          setState(() {
            final bool exists = _messages.any((m) => m['_id'] == data['_id']);
            if (!exists) {
              _messages.add(Map<String, dynamic>.from(data));
              if (!data['isRead']) {
                _unreadCount++;
              }
            }
          });
          _scrollToBottom();
        }
      }
    });

    _socket.on('message_sent', (data) {
      if (!_isDisposed && mounted) {
        print('✅ Message envoyé confirmé');
        setState(() {
          _isSending = false;
          _isLoading = false;
          if (data['tempId'] != null) {
            final index = _messages.indexWhere((m) => m['_id'] == data['tempId']);
            if (index != -1) {
              _messages[index] = Map<String, dynamic>.from(data['message']);
              _messages[index]['_id'] = data['message']['_id'];
              _messages[index]['isPending'] = false;
            }
          }
        });
        _messageController.clear();
        _attachedFiles.clear();
        _scrollToBottom();
      }
    });

    _socket.on('message_error', (data) {
      if (!_isDisposed && mounted) {
        print('❌ Erreur message: ${data['error']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${data['error']}'), backgroundColor: Colors.red),
          );
          if (data['tempId'] != null) {
            setState(() {
              _messages.removeWhere((m) => m['_id'] == data['tempId']);
            });
          }
        }
        setState(() {
          _isSending = false;
          _isLoading = false;
        });
      }
    });

    _socket.on('message_read', (data) {
      if (!_isDisposed && mounted) {
        print('📖 Message lu: ${data['messageId']}');
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m['_id'] == data['messageId']);
            if (index != -1) {
              _messages[index]['isRead'] = true;
              if (_unreadCount > 0) _unreadCount--;
            }
          });
        }
      }
    });

    _socket.on('user_typing', (data) {
      if (!_isDisposed && mounted) {
        if (mounted) {
          setState(() {
            _isTyping = data['isTyping'];
          });
        }
      }
    });

    _socket.on('force_logout', (_) {
      if (!_isDisposed && mounted) {
        print('⚠️ Déconnecté par le serveur');
        _socket.disconnect();
      }
    });

    _socket.on('disconnect', (_) {
      if (!_isDisposed && mounted) {
        print('🔴 Déconnecté du serveur WebSocket');
        if (mounted) {
          setState(() {
            _isConnected = false;
          });
        }
      }
    });

    _socket.on('connect_error', (data) {
      if (!_isDisposed && mounted) {
        print('❌ Erreur de connexion WebSocket: $data');
      }
    });
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getMessages(widget.contactId);
      
      if (!mounted) return;
      
      if (result['success']) {
        final List<dynamic> messages = result['messages'] ?? [];
        int unread = 0;
        
        setState(() {
          _messages.clear();
          for (var msg in messages) {
            final isMe = msg['senderId'].toString() != widget.contactId;
            final isRead = msg['isRead'] ?? false;
            _messages.add(Map<String, dynamic>.from(msg));
            if (!isMe && !isRead) {
              unread++;
            }
          }
          _unreadCount = unread;
          _isLoading = false;
        });
        
        _scrollToBottom();
        
        if (unread > 0 && widget.onMessagesRead != null) {
          widget.onMessagesRead!();
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur chargement messages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTyping() {
    if (!_isConnected || !mounted) return;
    
    if (_typingTimer != null) {
      _typingTimer!.cancel();
    } else {
      _socket.emit('typing', {
        'receiverId': widget.contactId,
        'isTyping': true,
      });
    }
    
    _typingTimer = Timer(const Duration(seconds: 1), () {
      if (!_isDisposed && mounted && _isConnected) {
        _socket.emit('typing', {
          'receiverId': widget.contactId,
          'isTyping': false,
        });
      }
      _typingTimer = null;
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photo != null) {
        final File file = File(photo.path);
        final int size = await file.length();
        
        if (size > 10 * 1024 * 1024) {
          _showSnackBar('L\'image dépasse 10MB', Colors.orange);
          return;
        }
        
        setState(() {
          _attachedFiles.add({
            'name': photo.name,
            'path': photo.path,
            'size': size,
            'file': file,
            'type': 'image',
          });
        });
        _showSnackBar('📸 Photo ajoutée: ${photo.name}', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', Colors.red);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        final File file = File(image.path);
        final int size = await file.length();
        
        if (size > 10 * 1024 * 1024) {
          _showSnackBar('L\'image dépasse 10MB', Colors.orange);
          return;
        }
        
        setState(() {
          _attachedFiles.add({
            'name': image.name,
            'path': image.path,
            'size': size,
            'file': file,
            'type': 'image',
          });
        });
        _showSnackBar('🖼️ Image ajoutée: ${image.name}', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', Colors.red);
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'gif', 'txt', 'doc', 'docx', 'mp4', 'mp3'],
      );
      
      if (result != null && mounted) {
        for (var file in result.files) {
          if (file.path != null) {
            if (file.size > 10 * 1024 * 1024) {
              _showSnackBar('Le fichier ${file.name} dépasse 10MB', Colors.orange);
              continue;
            }
            
            final File fileObj = File(file.path!);
            final bool exists = await fileObj.exists();
            
            if (exists) {
              setState(() {
                _attachedFiles.add({
                  'name': file.name,
                  'path': file.path,
                  'size': file.size,
                  'file': fileObj,
                  'type': _getFileType(file.name),
                });
              });
              _showSnackBar('📎 ${file.name} ajouté', Colors.green);
            } else {
              _showSnackBar('Le fichier ${file.name} n\'existe pas', Colors.orange);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur: $e', Colors.red);
      }
    }
  }

  String _getFileType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['mp4', 'avi', 'mov'].contains(ext)) return 'video';
    if (['mp3', 'wav'].contains(ext)) return 'audio';
    if (['pdf'].contains(ext)) return 'pdf';
    if (['doc', 'docx'].contains(ext)) return 'word';
    return 'file';
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  void _showAttachmentOptions() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ajouter une pièce jointe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0288D1), size: 28),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF4CAF9F), size: 28),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Color(0xFFFF9800), size: 28),
                title: const Text('Ajouter un fichier'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _removeFile(int index) {
    if (mounted) {
      setState(() {
        _attachedFiles.removeAt(index);
      });
    }
  }

  Future<void> _downloadAndOpenFile(String filename, String originalName) async {
    try {
      _showSnackBar('Téléchargement en cours...', Colors.blue);
      
      final result = await ApiService.downloadFile(filename, originalName);
      
      if (result['success']) {
        final String filePath = result['filePath'];
        final String fileName = result['fileName'];
        
        _showSnackBar('✅ Fichier téléchargé: $fileName', Colors.green);
        
        final openResult = await OpenFile.open(filePath);
        
        if (openResult.type != ResultType.done) {
          _showSnackBar('Impossible d\'ouvrir le fichier', Colors.orange);
        }
      } else {
        _showSnackBar('❌ Erreur: ${result['message']}', Colors.red);
      }
    } catch (e) {
      print('❌ Erreur download: $e');
      _showSnackBar('Erreur: $e', Colors.red);
    }
  }

  Future<void> _sendMessage() async {
    if (!mounted) return;
    if (_isSending) return;
    
    final bool hasText = _messageController.text.trim().isNotEmpty;
    final bool hasFiles = _attachedFiles.isNotEmpty;
    
    if (!hasText && !hasFiles) return;
    
    setState(() {
      _isSending = true;
      _isLoading = true;
    });
    
    List<Map<String, dynamic>> uploadedFiles = [];
    
    for (var fileData in _attachedFiles) {
      if (fileData.containsKey('file') && fileData['file'] != null) {
        try {
          print('📤 Upload du fichier: ${fileData['name']}');
          
          final uploadResult = await ApiService.uploadFile(fileData['file']);
          
          if (uploadResult['success']) {
            uploadedFiles.add({
              'filename': uploadResult['file']['filename'],
              'originalName': uploadResult['file']['originalName'],
              'fileType': uploadResult['file']['fileType'],
              'fileSize': uploadResult['file']['fileSize'],
              'filePath': uploadResult['file']['filePath'],
            });
            print('✅ Fichier uploadé: ${uploadResult['file']['originalName']}');
          } else {
            print('❌ Erreur upload: ${uploadResult['message']}');
            _showSnackBar('Erreur upload: ${uploadResult['message']}', Colors.red);
          }
        } catch (e) {
          print('❌ Exception upload: $e');
          _showSnackBar('Erreur upload: $e', Colors.red);
        }
      }
    }
    
    final messageText = _messageController.text.trim();
    final String finalMessage = messageText.isEmpty && uploadedFiles.isNotEmpty 
        ? "📎 Fichier joint" 
        : messageText;
    
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final localMessage = {
      '_id': tempId,
      'message': finalMessage,
      'senderId': widget.teacherId,
      'senderName': widget.teacherName,
      'receiverId': widget.contactId,
      'receiverName': widget.contactName,
      'receiverRole': widget.contactRole,
      'attachments': uploadedFiles,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
      'isPending': true,
    };
    
    setState(() {
      _messages.add(localMessage);
    });
    _scrollToBottom();
    
    if (_isConnected) {
      _socket.emit('send_message', {
        'receiverId': widget.contactId,
        'receiverName': widget.contactName,
        'receiverRole': widget.contactRole,
        'message': finalMessage,
        'senderId': widget.teacherId,
        'senderName': widget.teacherName,
        'attachments': uploadedFiles,
        'tempId': tempId,
      });
      print('📤 Message envoyé via WebSocket avec ${uploadedFiles.length} fichier(s)');
    } else {
      _showSnackBar('Non connecté au serveur', Colors.orange);
      setState(() {
        _isSending = false;
        _isLoading = false;
        _messages.removeWhere((m) => m['_id'] == tempId);
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}min';
    } else {
      return 'maintenant';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Text(
                    _contactInfo?['avatar'] ?? '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0288D1),
                    ),
                  ),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.contactName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      if (_isTyping)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'écrit...',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      if (_unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _unreadCount > 9 ? '9+' : '$_unreadCount',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.contactRole == 'parent' ? 'Parent' : (widget.contactRole == 'teacher' ? 'Enseignant' : 'Élève'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        actions: [
          if (_isConnected)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.wifi, size: 16, color: Colors.green),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    reverse: false,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['senderId'].toString() != widget.contactId;
                      final isPending = message['isPending'] == true;
                      return _buildMessageBubble(
                        message['message'],
                        isMe,
                        _formatDate(DateTime.parse(message['createdAt'])),
                        message['attachments'] ?? [],
                        message['isRead'] ?? false,
                        isPending,
                      );
                    },
                  ),
          ),

          if (_attachedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _attachedFiles[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconForFile(file['type']),
                            size: 16,
                            color: const Color(0xFF0288D1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            file['name'].length > 20 ? '${file['name'].substring(0, 20)}...' : file['name'],
                            style: const TextStyle(fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => _removeFile(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Color(0xFF0288D1)),
                  onPressed: _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (value) => _onTyping(),
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 4,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF0288D1),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForFile(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_library;
      case 'audio':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'word':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildMessageBubble(String text, bool isMe, String time, List<dynamic> attachments, bool isRead, bool isPending) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0288D1) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (attachments.isNotEmpty) ...[
              ...attachments.map((file) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _downloadAndOpenFile(file['filename'], file['originalName']),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconForFileType(file['fileType']),
                        size: 20,
                        color: isMe ? Colors.white70 : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          file['originalName'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isMe ? Colors.white70 : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(width: 4),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
                if (isMe && !isPending) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: isRead ? Colors.green : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForFileType(String fileType) {
    if (fileType == '.pdf') return Icons.picture_as_pdf;
    if (fileType == '.jpg' || fileType == '.png' || fileType == '.jpeg' || fileType == '.webp') return Icons.image;
    if (fileType == '.doc' || fileType == '.docx') return Icons.description;
    if (fileType == '.mp4') return Icons.video_library;
    if (fileType == '.mp3') return Icons.audiotrack;
    return Icons.insert_drive_file;
  }
}