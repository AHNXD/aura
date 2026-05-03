import 'package:aura/viewmodel/chat_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel()..initializeChat(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Center(
            child: Text(
              'Medical Assistant',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          elevation: 0,
          backgroundColor: const Color(0xFF6899F8),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        body: Consumer<ChatViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                // Chat messages list
                Expanded(
                  child: viewModel.messages.isEmpty
                      ? Center(
                          child: Text(
                            'No messages yet',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          reverse: false,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          itemCount: viewModel.messages.length,
                          itemBuilder: (context, index) {
                            final message = viewModel.messages[index];
                            return _buildMessageBubble(message, context);
                          },
                        ),
                ),
                // Input area
                _buildInputArea(context, viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build individual message bubble
  Widget _buildMessageBubble(Message message, BuildContext context) {
    if (message.isLoading) {
      return _buildTypingIndicator();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: message.isUser
                ? const Color(0xFF6899F8)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            message.text,
            style: TextStyle(
              color: message.isUser ? Colors.white : Colors.black,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// Build typing indicator animation
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(0),
              const SizedBox(width: 4),
              _buildDot(1),
              const SizedBox(width: 4),
              _buildDot(2),
            ],
          ),
        ),
      ),
    );
  }

  /// Build animated dot for typing indicator
  Widget _buildDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        shape: BoxShape.circle,
      ),
    );
  }

  /// Build input area with text field and send button
  Widget _buildInputArea(BuildContext context, ChatViewModel viewModel) {
    final TextEditingController textController = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        child: Row(
          children: [
            // Text input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey[300] ?? Colors.grey,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Type your symptoms...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      viewModel.sendMessage(value);
                      textController.clear();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF6899F8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () {
                        if (textController.text.isNotEmpty) {
                          viewModel.sendMessage(textController.text);
                          textController.clear();
                        }
                      },
                icon: Icon(
                  Icons.send,
                  color: viewModel.isLoading ? Colors.grey : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
