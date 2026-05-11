import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/chat_service.dart';
import 'widgets/top_navbar.dart'; // Import Navbar konsisten

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  int? roomId;
  List messages = [];
  int? userId;
  bool isPolling = true;
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initChat();
  }

  Future<void> initChat() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    final id = await ChatService.getRoom();
    final msgs = await ChatService.getMessages(id);

    if (!mounted) return;

    setState(() {
      roomId = id;
      messages = msgs;
    });
    
    _scrollToBottom();
    startPolling();
  }

  void startPolling() async {
    while (isPolling) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || roomId == null) return;

      final msgs = await ChatService.getMessages(roomId!);
      if (!mounted) return;

      if (msgs.length != messages.length) {
        setState(() {
          messages = msgs;
        });
        _scrollToBottom();
      }
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

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty || roomId == null) return;

    final text = controller.text;
    controller.clear();

    await ChatService.sendMessage(roomId!, text);
    final msgs = await ChatService.getMessages(roomId!);

    if (!mounted) return;
    setState(() {
      messages = msgs;
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    isPolling = false;
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget chatBubble(Map msg) {
    final isMe = msg['pengirim_id'] == userId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF1E56A0) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              msg['pesan'],
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF1B3D5F),
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 25,
              right: isMe ? 25 : 0,
              bottom: 8,
            ),
            child: Text(
              msg['waktu_kirim'] ?? '',
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9), // Warna background konsisten
      body: Column(
        children: [
          const TopNavbar(), // Navbar atas konsisten

          // Sub-Header dengan tombol kembali
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E56A0)),
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  "Bantuan Admin",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F)),
                ),
              ],
            ),
          ),

          // Area Chat
          Expanded(
            child: messages.isEmpty 
            ? const Center(child: Text("Belum ada pesan. Silakan hubungi admin."))
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 10),
                itemCount: messages.length,
                itemBuilder: (context, index) => chatBubble(messages[index]),
              ),
          ),

          // Input Bar Modern
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
              ]
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Tulis pesan ke admin...",
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E56A0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}