// lib/staff_chat_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StaffChatPage extends StatefulWidget {
  final String ticketId;
  final String customerName;
  final String phone;

  const StaffChatPage({
    super.key,
    required this.ticketId,
    required this.customerName,
    required this.phone,
  });

  @override
  State<StaffChatPage> createState() => _StaffChatPageState();
}

class _StaffChatPageState extends State<StaffChatPage> {
  final TextEditingController _msg = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String chatId;

  @override
  void initState() {
    super.initState();
    chatId = "${widget.ticketId}_${widget.phone}";
  }

  void sendMessage() async {
    if (_msg.text.trim().isEmpty) return;

    String text = _msg.text.trim();
    _msg.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'sender': 'staff',
      'time': Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'ticketId': widget.ticketId,
      'phone': widget.phone,
      'customerName': widget.customerName,
      'lastMessage': text,
      'lastTime': Timestamp.now(),
      'sender': 'staff',
    }, SetOptions(merge: true));

    // Scroll to bottom
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

  @override
  void dispose() {
    _msg.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 2,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Ticket: ${widget.ticketId}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('time')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var data = messages[index].data() as Map<String, dynamic>;
                    bool isStaff = data['sender'] == 'staff';
                    String text = data['text'] ?? '';
                    Timestamp? time = data['time'];
                    String timeStr = time != null ? DateFormat('hh:mm a').format(time.toDate()) : '';

                    return Align(
                      alignment: isStaff ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: isStaff ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Column(
                          crossAxisAlignment: isStaff ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: TextStyle(color: isStaff ? Colors.white : Colors.black87, fontSize: 16.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: TextStyle(color: isStaff ? Colors.white70 : Colors.grey[600], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT BAR — SAME AS MOBILE
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
            decoration: const BoxDecoration(
              color: Color(0xffF5F5F5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -3),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _msg,
                      decoration: const InputDecoration(
                        hintText: "Reply...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 22),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}