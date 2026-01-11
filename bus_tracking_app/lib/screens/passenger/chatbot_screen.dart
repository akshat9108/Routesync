import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:RouteSync/services/location_service.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user');
  final _bot = const types.User(id: 'bot', firstName: 'Bus Bot');

  @override
  void initState() {
    super.initState();
    _addBotMessage("👋 Welcome! Ask me about bus locations, ETA, routes, or nearby buses.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chatbot"), backgroundColor: Colors.teal),
      body: Column(
        children: [
          Expanded(
            child: Chat(
              messages: _messages,
              onSendPressed: _handleSendPressed,
              user: _user,
              theme: const DefaultChatTheme(inputBackgroundColor: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );
    _addMessage(textMessage);
    _processUserMessage(message.text.toLowerCase());
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _addBotMessage(String text) {
    final message = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: text,
    );
    _addMessage(message);
  }

  Future<void> _processUserMessage(String userMessage) async {
    _showTyping();
    await Future.delayed(const Duration(seconds: 1));
    _removeTyping();

    if (userMessage.contains("where is bus")) {
      final busId = userMessage.replaceAll(RegExp(r'[^0-9]'), '');
      if (busId.isNotEmpty) {
        _addBotMessage("📍 Fetching location for Bus $busId...");
        try {
          DatabaseReference ref = FirebaseDatabase.instance.ref("buses/$busId");
          final snapshot = await ref.get();
          if (snapshot.exists) {
            final data = snapshot.value as Map;
            _addBotMessage("Bus $busId is at (${data['latitude']}, ${data['longitude']})");
          } else {
            _addBotMessage("❌ Bus $busId location not found.");
          }
        } catch (e) {
          _addBotMessage("⚠️ Error fetching location for Bus $busId: $e");
        }
      } else {
        _addBotMessage("❌ Please specify a valid bus number.");
      }
    } else if (userMessage.contains("nearby")) {
      try {
        Position pos = await LocationService().getCurrentLocationOnce();
        _addBotMessage("🚏 Nearby buses near (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})");
      } catch (e) {
        _addBotMessage("⚠️ Could not fetch nearby buses: $e");
      }
    } else if (userMessage.contains("hello") || userMessage.contains("hi")) {
      _addBotMessage("👋 Hello! Ask me about buses, routes, or nearby stops.");
    } else {
      _addBotMessage("🤔 Try asking: 'Where is Bus 101?', 'ETA for Bus 101', or 'Nearby buses'.");
    }
  }

  void _showTyping() {
    final typing = types.TextMessage(author: _bot, createdAt: DateTime.now().millisecondsSinceEpoch, id: "typing", text: "...");
    _addMessage(typing);
  }

  void _removeTyping() {
    setState(() {
      _messages.removeWhere((msg) => msg.id == "typing");
    });
  }
}
