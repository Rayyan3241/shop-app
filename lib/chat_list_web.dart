// lib/chat_list_web.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'staff_chat_page.dart';

class ChatListWeb extends StatefulWidget {
  const ChatListWeb({super.key});

  @override
  State<ChatListWeb> createState() => _ChatListWebState();
}

class _ChatListWebState extends State<ChatListWeb> {
  String? selectedChatId; // Currently opened chat
  Map<String, dynamic>? selectedChatData;

  String _formatTime(Timestamp timestamp) {
    final DateTime time = timestamp.toDate();
    final now = DateTime.now();

    if (now.day == time.day && now.month == time.month && now.year == time.year) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }

    return "${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}";
  }

  void _openChat(String chatId, Map<String, dynamic> data) {
    setState(() {
      selectedChatId = chatId;
      selectedChatData = data;

      // Mark as read (same logic as before)
      FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({'unreadForStaff': false});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: Row(
        children: [
          // LEFT SIDE: Chat List
          Container(
            width: 380,
            color: Colors.blueGrey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 20),
                  child: Text(
                    'Inbox',
                    style: GoogleFonts.poppins(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .orderBy('lastTime', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final chats = snapshot.data!.docs;

                      if (chats.isEmpty) {
                        return Center(
                          child: Text(
                            "No chats yet",
                            style: GoogleFonts.poppins(fontSize: 24, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: chats.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final data = chat.data() as Map<String, dynamic>;
                          final name = data['customerName'] ?? "Unknown";
                          final lastMessage = data['lastMessage'] ?? "";
                          final unread = data['unreadForStaff'] ?? false;
                          final time = data['lastTime'] != null ? _formatTime(data['lastTime']) : "";

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            selected: selectedChatId == chat.id,
                            selectedTileColor: Colors.grey[100],
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blueGrey.shade900,
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                if (unread)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              name,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            trailing: Text(
                              time,
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            onTap: () => _openChat(chat.id, data),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // RIGHT SIDE: Selected Chat or Placeholder
          Expanded(
            child: selectedChatId == null
                ? Center(
              child: Text(
                "Select a chat to start messaging",
                style: GoogleFonts.poppins(fontSize: 24, color: Colors.grey[600]),
              ),
            )
                : StaffChatPage(
              ticketId: selectedChatData!['ticketId'] ?? '',
              customerName: selectedChatData!['customerName'] ?? 'Unknown',
              phone: selectedChatData!['phone'] ?? '',
            ),
          ),
        ],
      ),
    );
  }
}