import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// Import our secure, unified API service
import 'package:nirogx_app/services/api_service.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialMessage; // Accepts messages from other screens

  const AiChatScreen({super.key, this.initialMessage});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // If a message was passed in when the screen first loads, send it!
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textController.text = widget.initialMessage!;
        _sendMessage();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AiChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the user navigates here from another tab with a NEW message, send it!
    if (widget.initialMessage != null && widget.initialMessage != oldWidget.initialMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textController.text = widget.initialMessage!;
        _sendMessage();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Pick an image from Camera or Gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80, // Compress slightly for faster API uploads
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  // Live API Communication Logic
  Future<void> _sendMessage() async {
    final String message = _textController.text.trim();
    
    // Prevent sending empty requests
    if (message.isEmpty && _selectedImage == null) return;

    // Default text if they only send an image
    final String prompt = message.isEmpty ? "Please analyze this medical image/report." : message;

    Uint8List? imageBytes;
    File? imageFile;

    // Extract bytes if an image is attached
    if (_selectedImage != null) {
      imageBytes = await _selectedImage!.readAsBytes();
      imageFile = File(_selectedImage!.path);
    }

    setState(() {
      // We store the File locally to render it in the chat bubble
      _messages.add({
        'sender': 'user', 
        'text': prompt,
        'image': imageFile, 
      });
      _isLoading = true;
      _selectedImage = null; // Clear attachment after sending
    });
    
    _scrollToBottom();
    _textController.clear();

    try {
      // Calls the secure Gemini integration with optional image
      final response = await _apiService.sendChatMessage(prompt, imageBytes: imageBytes);
      
      if (!mounted) return;

      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': response,
          'image': null,
        });
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'I encountered a network error. Please check your connection.',
          'image': null,
        });
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color nirogTeal = Color(0xFF00C9B7);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          'NirogX AI Assistant',
          style: GoogleFonts.poppins(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.grey, size: 20),
            onPressed: () => setState(() {
              _messages.clear();
              _selectedImage = null;
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty 
              ? _buildEmptyState(nirogTeal)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    bool isUser = message['sender'] == 'user';
                    return _buildMessageBubble(
                      text: message['text'] as String, 
                      isUser: isUser,
                      imageFile: message['image'] as File?,
                    );
                  },
                ),
          ),
          if (_isLoading) _buildLoadingIndicator(nirogTeal),
          if (_selectedImage != null) _buildImagePreview(), // Show pending image
          _buildInputBar(nirogTeal),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bot, size: 64, color: color.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            "How can I help with your health today?",
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({required String text, required bool isUser, File? imageFile}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF00C9B7) : const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(imageFile, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              text, 
              style: GoogleFonts.poppins(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shows the image waiting to be sent above the text box
  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_selectedImage!.path),
              height: 50,
              width: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Image Attached',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.xCircle, color: Colors.redAccent, size: 20),
            onPressed: () => setState(() => _selectedImage = null),
          )
        ],
      ),
    );
  }

  Widget _buildInputBar(Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]
      ),
      child: Row(
        children: [
          // Attachment Button
          IconButton(
            icon: const Icon(LucideIcons.paperclip, color: Colors.grey),
            onPressed: () {
              // Quick bottom sheet to choose Camera or Gallery
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Wrap(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(LucideIcons.camera),
                          title: const Text('Take a photo'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(LucideIcons.image),
                          title: const Text('Choose from gallery'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  );
                }
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask or attach report...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F4F8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: color,
            child: IconButton(
              icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: color)),
          const SizedBox(width: 8),
          Text("NirogX is analyzing...", style: GoogleFonts.poppins(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}