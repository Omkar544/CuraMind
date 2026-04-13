// frontend/lib/widgets/navbar.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';

// Assuming this is intended as a chatbot floating action button that opens a chat window
// If this is meant to be a full bottom navigation bar, the name 'navbar' is misleading
// and the implementation needs to be changed. For now, I'm treating it as a chatbot widget.

class TalkBuddyChatbot extends StatefulWidget {
  const TalkBuddyChatbot({super.key});

  @override
  _TalkBuddyChatbotState createState() => _TalkBuddyChatbotState();
}

class _TalkBuddyChatbotState extends State<TalkBuddyChatbot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final TextEditingController _textController = TextEditingController();
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;
    _textController.clear();
    setState(() {
      _messages.insert(0, text); // Add message to the top
    });
    // TODO: Add actual chatbot response logic here
  }

  void _toggleChat() {
    if (_controller.isDismissed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24.0,
      right: 24.0,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Chat window
          FadeTransition(
            opacity: _animation,
            child: ScaleTransition(
              scale: _animation,
              alignment:
                  Alignment.bottomRight, // Make it expand from the button
              child: _buildChatWindow(),
            ),
          ),
          // Floating Action Button for Chatbot
          SizedBox(
            width: 70, // Increased size for the button
            height: 70, // Increased size for the button
            child: FloatingActionButton(
              onPressed: _toggleChat,
              backgroundColor: AppColors.primaryTeal,
              child: Image.asset(
                'assets/logos/Curamind_chatbot.png', // <-- Ensure this path is correct
                height: 40,
                color: AppColors
                    .textLightest, // Make chatbot logo white for contrast
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.chat_bubble_outline,
                      size: 40, color: AppColors.textLightest); // Fallback icon
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatWindow() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: 400,
      decoration: AppStyles.cardDecoration,
      margin: const EdgeInsets.only(bottom: 80), // Move up to not overlap FAB
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true, // Show latest messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (_, int index) {
                // Simple chat bubble for demonstration
                return Align(
                  alignment:
                      Alignment.centerRight, // User messages to the right
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _messages[index],
                      style: AppStyles.bodyStyle
                          .copyWith(color: AppColors.textLightest),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: const IconThemeData(color: AppColors.primaryTeal),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: "Send a message...",
                ),
                style: AppStyles.bodyStyle, // Apply custom text style
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
