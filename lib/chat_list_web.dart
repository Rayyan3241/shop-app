// lib/chat_list_web.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'staff_chat_page.dart';

class ChatListWeb extends StatelessWidget {
  const ChatListWeb({super.key});

  String _formatTime(Timestamp timestamp) {
    final DateTime time = timestamp.toDate();
    final now = DateTime.now();

    if (now.day == time.day && now.month == time.month && now.year == time.year) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }

    return "${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Chats',
                style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15)],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue[300],
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
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      trailing: Text(
                        time,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      onTap: () {
                        // Mark as read
                        FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chat.id)
                            .update({'unreadForStaff': false});

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StaffChatPage(
                              ticketId: data['ticketId'] ?? '',
                              customerName: name,
                              phone: data['phone'] ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}