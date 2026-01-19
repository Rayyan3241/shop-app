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
    chatId = _computeChatId();
    _markCustomerMessagesAsRead();
  }

  @override
  void didUpdateWidget(StaffChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticketId != widget.ticketId ||
        oldWidget.phone != widget.phone) {
      setState(() {
        chatId = _computeChatId();
      });
      _markCustomerMessagesAsRead();
    }
  }

  String _computeChatId() {
    return "${widget.ticketId}_${widget.phone}";
  }

  Future<void> _markCustomerMessagesAsRead() async {
    final query = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('sender', isEqualTo: 'customer')
        .where('readByStaff', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'readByStaff': true});
    }

    await batch.commit();

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set(
      {
        'unreadForStaff': false,
      },
      SetOptions(merge: true),
    );
  }

  void sendMessage() async {
    if (_msg.text.trim().isEmpty) return;

    String text = _msg.text.trim();
    _msg.clear();

    final now = Timestamp.now();

    // NOTE: if you also allow swipe‑reply on staff side,
    // you would add replyToText / replyToSender here as well.

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'sender': 'staff',
      'fromStaff': true,
      'readByCustomer': false,
      'readByStaff': true,
      'time': now,
      // 'replyToText': ...,    // <-- add later if you implement staff reply
      // 'replyToSender': ...,  // <-- add later if you implement staff reply
    });

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'ticketId': widget.ticketId,
      'phone': widget.phone,
      'customerName': widget.customerName,
      'lastMessage': text,
      'lastTime': now,
      'sender': 'staff',
      'unreadForCustomer': true,
    }, SetOptions(merge: true));

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
        backgroundColor: Colors.blueGrey.shade900,
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
                  style:
                  const TextStyle(fontSize: 14, color: Colors.white70),
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
                    var data =
                    messages[index].data() as Map<String, dynamic>;

                    bool isStaff = data['sender'] == 'staff';
                    String text = data['text'] ?? '';
                    Timestamp? time = data['time'];
                    String timeStr = time != null
                        ? DateFormat('h:mm a').format(time.toDate())
                        : '';

                    // 👇 reply info from customer side (if this message is a reply)
                    final String replyToText =
                    (data['replyToText'] ?? '') as String;
                    final String replyToSender =
                    (data['replyToSender'] ?? '') as String;

                    return Align(
                      alignment: isStaff
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: isStaff
                              ? Colors.blueGrey.shade900
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          maxWidth:
                          MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: isStaff
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            // 👇 replied customer message (only if exists)
                            if (replyToText.isNotEmpty)
                              Container(
                                margin:
                                const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isStaff
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.grey.shade200,
                                  borderRadius:
                                  BorderRadius.circular(8),
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.blueGrey.shade300,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    if (replyToSender.isNotEmpty)
                                      Text(
                                        replyToSender,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isStaff
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      replyToText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isStaff
                                            ? Colors.white70
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // main message
                            Text(
                              text,
                              style: TextStyle(
                                color: isStaff
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 16.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: isStaff
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 11,
                              ),
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

          // INPUT BAR
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
            decoration: const BoxDecoration(
              color: Color(0xffF5F5F5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 18),
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
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 22,
                    ),
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
