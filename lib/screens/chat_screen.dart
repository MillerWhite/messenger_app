import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  ChatScreen({required this.receiverId, required this.receiverName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User _currentUser = FirebaseAuth.instance.currentUser!;
  String _chatId = '';

  @override
  void initState() {
    super.initState();
    _chatId = _getChatId(_currentUser.uid, widget.receiverId);
  }

  String _getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '$uid1$uid2' : '$uid2$uid1';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _firestore.collection('chats').doc(_chatId).collection('messages').add({
      'senderId': _currentUser.uid,
      'receiverId': widget.receiverId,
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Обновляем последнее сообщение для списка чатов
    await _firestore.collection('chats').doc(_chatId).set({
      'lastMessage': _messageController.text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [_currentUser.uid, widget.receiverId],
    }, SetOptions(merge: true));

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index];
                    bool isMe = msg['senderId'] == _currentUser.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey[800],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                msg['text'],
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 4),
                              Text(
                                DateFormat('HH:mm').format(
                                  (msg['timestamp'] as Timestamp).toDate()
                                ),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}