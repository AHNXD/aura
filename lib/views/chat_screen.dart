import 'package:aura/models/chat_conversation.dart';
import 'package:aura/models/message.dart';
import 'package:aura/services/auth_service.dart';
import 'package:aura/theme/app_theme.dart';
import 'package:aura/viewmodel/chat_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ChatViewModel(context.read<AuthService>())..initializeChat(),
      child: const _ChatScreenBody(),
    );
  }
}

class _ChatScreenBody extends StatefulWidget {
  const _ChatScreenBody();

  @override
  State<_ChatScreenBody> createState() => _ChatScreenBodyState();
}

class _ChatScreenBodyState extends State<_ChatScreenBody> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _queueScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _sendMessage(ChatViewModel viewModel) {
    final text = _textController.text.trim();
    if (text.isEmpty || viewModel.isLoading || viewModel.isInitializing) {
      return;
    }

    viewModel.sendMessage(text);
    _textController.clear();
    _focusNode.requestFocus();
    _queueScrollToBottom();
  }

  Future<void> _showConversationSheet(ChatViewModel viewModel) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final sheetViewModel = viewModel;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GlassPanel(
              borderRadius: 30,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Saved conversations',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Switch between chats or start a fresh one.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed:
                          sheetViewModel.isInitializing ||
                              sheetViewModel.isLoading
                          ? null
                          : () async {
                              await sheetViewModel.createNewConversation();
                              if (!sheetContext.mounted) {
                                return;
                              }
                              Navigator.of(sheetContext).pop();
                            },
                      icon: const Icon(Icons.add_comment_rounded),
                      label: const Text('Start new chat'),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: sheetViewModel.conversations.isEmpty
                          ? const Center(
                              child: Text(
                                'No conversations yet.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: sheetViewModel.conversations.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final conversation =
                                    sheetViewModel.conversations[index];
                                final isActive =
                                    conversation.id ==
                                    sheetViewModel.activeConversationId;

                                return _ConversationListTile(
                                  conversation: conversation,
                                  isActive: isActive,
                                  onTap: () async {
                                    await sheetViewModel.selectConversation(
                                      conversation.id,
                                    );
                                    if (!sheetContext.mounted) {
                                      return;
                                    }
                                    Navigator.of(sheetContext).pop();
                                  },
                                  onDelete:
                                      sheetViewModel.isInitializing ||
                                          sheetViewModel.isLoading
                                      ? null
                                      : () async {
                                          final shouldDelete =
                                              await showDialog<bool>(
                                                context: sheetContext,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                      'Delete conversation?',
                                                    ),
                                                    content: Text(
                                                      'Remove "${conversation.title}" and its saved messages from this account?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).pop(false);
                                                        },
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).pop(true);
                                                        },
                                                        child: const Text(
                                                          'Delete',
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                          if (shouldDelete != true) {
                                            return;
                                          }

                                          await sheetViewModel
                                              .deleteConversation(
                                                conversation.id,
                                              );
                                          if (!sheetContext.mounted) {
                                            return;
                                          }
                                          Navigator.of(sheetContext).pop();
                                        },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, _) {
        _queueScrollToBottom();

        return Scaffold(
          body: AppBackground(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                _ChatHeader(
                  isBusy: viewModel.isLoading || viewModel.isInitializing,
                  currentTitle:
                      viewModel.activeConversation?.title ?? 'Loading chat',
                  onShowConversations: () => _showConversationSheet(viewModel),
                  onNewChat: viewModel.isInitializing || viewModel.isLoading
                      ? null
                      : () async {
                          await viewModel.createNewConversation();
                        },
                ),
                const SizedBox(height: 16),
                _ConversationSummaryCard(
                  conversationCount: viewModel.conversations.length,
                  currentLabel:
                      viewModel.activeConversation?.title ?? 'New chat',
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GlassPanel(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: viewModel.isInitializing
                        ? const _ChatHistoryLoadingState()
                        : Column(
                            children: [
                              if (viewModel.historyError != null) ...[
                                _HistoryNotice(
                                  message: viewModel.historyError!,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (viewModel.messages.isEmpty)
                                const Expanded(child: _EmptyConversationState())
                              else
                                Expanded(
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.only(bottom: 8),
                                    itemCount: viewModel.messages.length,
                                    itemBuilder: (context, index) {
                                      final message = viewModel.messages[index];
                                      return _MessageBubble(message: message);
                                    },
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                _Composer(
                  controller: _textController,
                  focusNode: _focusNode,
                  isLoading: viewModel.isLoading || viewModel.isInitializing,
                  onSend: () => _sendMessage(viewModel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.isBusy,
    required this.currentTitle,
    required this.onShowConversations,
    required this.onNewChat,
  });

  final bool isBusy;
  final String currentTitle;
  final VoidCallback onShowConversations;
  final VoidCallback? onNewChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aura Medical Assistant',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBusy
                          ? 'Syncing your conversation...'
                          : 'Secure chat history, saved per user account.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => context.read<AuthService>().signOut(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onShowConversations,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onNewChat,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.add_comment_rounded),
                label: const Text('New'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatHistoryLoadingState extends StatelessWidget {
  const _ChatHistoryLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 18),
          Text(
            'Restoring your chat',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading saved conversations for this account.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryNotice extends StatelessWidget {
  const _HistoryNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.cloud_off_outlined, color: Color(0xFFAA6E00)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A4E00),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationSummaryCard extends StatelessWidget {
  const _ConversationSummaryCard({
    required this.conversationCount,
    required this.currentLabel,
  });

  final int conversationCount;
  final String currentLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.library_books_outlined,
            title: 'Saved chats',
            value:
                '$conversationCount conversation${conversationCount == 1 ? '' : 's'}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.bookmark_outline_rounded,
            title: 'Current thread',
            value: currentLabel,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 24,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationListTile extends StatelessWidget {
  const _ConversationListTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final ChatConversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAF4FF) : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive
                ? AppTheme.primary.withValues(alpha: 0.24)
                : AppTheme.outline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isActive
                    ? AppTheme.heroGradient
                    : const LinearGradient(
                        colors: [Color(0xFFD9E6FF), Color(0xFFEFF4FF)],
                      ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isActive
                    ? Icons.forum_rounded
                    : Icons.chat_bubble_outline_rounded,
                color: isActive ? Colors.white : AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessagePreview.isEmpty
                        ? 'No messages yet'
                        : conversation.lastMessagePreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatConversationTime(conversation.updatedAt),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete conversation',
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversationState extends StatelessWidget {
  const _EmptyConversationState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Start the conversation',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Describe your symptoms, ask for wellness tips, or get a first-pass explanation before speaking to a clinician.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final timeLabel = _formatTime(message.timestamp);

    if (message.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Align(alignment: Alignment.centerLeft, child: _TypingBubble()),
      );
    }

    final bubbleDecoration = message.isUser
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2057D7), Color(0xFF29A9C0)],
            ),
            borderRadius: BorderRadius.circular(
              24,
            ).copyWith(bottomRight: const Radius.circular(8)),
          )
        : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              24,
            ).copyWith(bottomLeft: const Radius.circular(8)),
            border: Border.all(color: const Color(0xFFDCE7F7)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          );

    final textColor = message.isUser ? Colors.white : AppTheme.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.74,
          ),
          child: Column(
            crossAxisAlignment: message.isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                decoration: bubbleDecoration,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  timeLabel,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ).copyWith(bottomLeft: const Radius.circular(8)),
        border: Border.all(color: const Color(0xFFDCE7F7)),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final shifted = (_controller.value + (index * 0.18)) % 1;
              final opacity = 0.35 + (0.65 * (1 - (shifted - 0.5).abs() * 2));

              return Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      borderRadius: 28,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Describe symptoms or ask a health question...',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: isLoading ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.55),
                minimumSize: const Size(54, 54),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.arrow_upward_rounded),
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime timestamp) {
  final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final period = timestamp.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _formatConversationTime(DateTime timestamp) {
  final now = DateTime.now();
  final sameDay =
      now.year == timestamp.year &&
      now.month == timestamp.month &&
      now.day == timestamp.day;

  if (sameDay) {
    return _formatTime(timestamp);
  }

  return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
}
