// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../models/message_models.dart';
import '../services/message_service.dart';
import 'widgets/action_widgets.dart';
import 'widgets/category_selector.dart';
import 'widgets/message_bubble.dart';

/// The Messages Tab content widget.
class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab>
    with AutomaticKeepAliveClientMixin {
  final MessageService _service = MessageService(useMockData: false);
  final ScrollController _scrollController = ScrollController();

  List<MessageForum> _categories = [];
  List<MessageItem> _messages = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  bool _showScrollToBottom = false;

  // Interaction steps state
  final List<_InteractionStep> _interactionSteps = [];
  String? _aiSummaryResult;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData(scrollToBottom: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isAtBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100;
    if (_showScrollToBottom == isAtBottom) {
      setState(() => _showScrollToBottom = !isAtBottom);
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadData({bool scrollToBottom = false}) async {
    if (_messages.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final forums = await _service.fetchForumList();
      final messages = await _service.fetchMessages();

      if (mounted) {
        setState(() {
          _categories = [
            MessageForum(id: 'all', fid: 'all', fname: '全部消息', number: 0),
            ...forums,
          ];
          _messages = messages;
          _isLoading = false;
        });

        if (scrollToBottom) {
          // Scroll to bottom after loading
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadData(scrollToBottom: false);
  }

  void _onCategorySelect(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      _interactionSteps.clear();
      _aiSummaryResult = null;
    });
  }

  /// Get filtered messages based on selected category
  List<MessageItem> get _filteredMessages {
    if (_selectedCategory == 'all') {
      return _messages;
    }
    return _messages.where((m) => m.forum == _selectedCategory).toList();
  }

  /// Get unread count for current category
  int get _unreadCount => _filteredMessages.where((m) => !m.isRead).length;

  /// Get category name for display
  String get _categoryName {
    if (_selectedCategory == 'all') return '';
    final cat = _categories.firstWhere(
      (c) => c.fid == _selectedCategory,
      orElse: () => MessageForum(id: '', fid: '', fname: '', number: 0),
    );
    return cat.fname;
  }

  void _onTriggerAiSummary() {
    setState(() {
      _interactionSteps.add(_InteractionStep.userRequestSummary);
      _interactionSteps.add(_InteractionStep.aiSummaryLoading);
      _aiSummaryResult = '';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    _service.triggerAiSummaryStream(_selectedCategory).listen(
      (text) {
        if (mounted) {
          setState(() {
            _aiSummaryResult = text;
            // Transition from loading to result if needed
            if (_interactionSteps.last == _InteractionStep.aiSummaryLoading) {
              _interactionSteps.removeLast();
              _interactionSteps.add(_InteractionStep.aiSummaryResult);
            }
          });
          // Auto-scroll to bottom while streaming
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }
      },
      onDone: () {
        if (mounted) {
          // Add mark as read action when done, if not already there
          if (!_interactionSteps
              .contains(_InteractionStep.aiMarkAsReadAction)) {
            setState(() =>
                _interactionSteps.add(_InteractionStep.aiMarkAsReadAction));
          }
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }
      },
      onError: (Object e) {
        if (mounted) {
          setState(() {
            // Handle error by removing loading/result steps
            _interactionSteps.removeWhere((s) =>
                s == _InteractionStep.aiSummaryLoading ||
                s == _InteractionStep.aiSummaryResult);
            _aiSummaryResult = 'AI 总结请求失败: $e';
            _interactionSteps.add(_InteractionStep.aiSummaryResult);
          });
        }
      },
    );
  }

  Future<void> _onMarkAsRead() async {
    setState(() {
      _interactionSteps.add(_InteractionStep.userMarkAsRead);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final msgIds =
        _filteredMessages.where((m) => !m.isRead).map((m) => m.msgid).toList();

    if (msgIds.isEmpty) {
      // Even if empty, show success if user clicked it
      setState(() {
        _interactionSteps.add(_InteractionStep.aiMarkAsReadSuccess);
      });
      return;
    }

    final success = await _service.markAsRead(msgIds);

    if (mounted) {
      setState(() {
        if (success) {
          _interactionSteps.add(_InteractionStep.aiMarkAsReadSuccess);
        } else {
          _interactionSteps.add(_InteractionStep.aiMarkAsReadFailure);
        }
      });

      // Reload data to reflect read status
      if (success) {
        _loadData();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            // Message list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                backgroundColor: const Color(0xFF1E2A3D),
                color: const Color(0xFFFF8C00),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: _getDisplayItems().length,
                  itemBuilder: (context, index) {
                    return _buildListItem(_getDisplayItems()[index]);
                  },
                ),
              ),
            ),
            // Category selector at bottom
            if (_categories.isNotEmpty)
              CategorySelector(
                categories: _categories,
                selectedId: _selectedCategory,
                onSelect: _onCategorySelect,
              ),
          ],
        ),
        // Scroll to bottom button
        if (_showScrollToBottom)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B7EFF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '回到最新',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<_DisplayItem> _getDisplayItems() {
    final items = <_DisplayItem>[];
    final messages = _filteredMessages;

    // Sort messages by time ascending (oldest first, newest at bottom)
    final sortedMessages = List<MessageItem>.from(messages)
      ..sort((a, b) => a.createtime.compareTo(b.createtime));

    // Build display items with time headers
    String? lastTimeKey;
    for (final msg in sortedMessages) {
      final timeKey = _formatSmartTime(msg.createDateTime);
      if (timeKey != lastTimeKey) {
        items.add(_DisplayItem.dateHeader(timeKey));
        lastTimeKey = timeKey;
      }
      items.add(_DisplayItem.message(msg));
    }

    // Add initial prompt if we haven't started interacting yet and have unread items
    if (_unreadCount > 0 && _interactionSteps.isEmpty) {
      items.add(_DisplayItem.summaryPrompt(_unreadCount, _categoryName));
    }

    // Add interaction steps
    for (final step in _interactionSteps) {
      switch (step) {
        case _InteractionStep.userRequestSummary:
          final text = _categoryName.isEmpty
              ? '全部未读消息AI总结'
              : '未读消息AI总结'; // Shortened for user bubble
          items.add(_DisplayItem.userMessage(text));
          break;
        case _InteractionStep.aiSummaryLoading:
          // Show nothing or a loading bubble?
          // For now, let's show the result bubble which handles loading state if text is empty/partial?
          // Actually, we use aiSummaryResult step for the content.
          // Maybe just show a placeholder?
          // Let's rely on aiSummaryResult being populated with partial text.
          // If it is just loading and empty text, maybe we show nothing or "..."
          break;
        case _InteractionStep.aiSummaryResult:
          if (_aiSummaryResult != null) {
            final title = _categoryName.isEmpty
                ? '全部未读消息AI总结'
                : '"$_categoryName"栏目未读消息AI总结';
            items.add(_DisplayItem.summaryResult(_aiSummaryResult!, title));
          }
          break;
        case _InteractionStep.aiMarkAsReadAction:
          final title = _categoryName.isEmpty ? '全部' : '"$_categoryName"栏目';
          items.add(_DisplayItem.markAsReadAction(title));
          break;
        case _InteractionStep.userMarkAsRead:
          items.add(_DisplayItem.userMessage('对上述已总结的消息全部标为已读'));
          break;
        case _InteractionStep.aiMarkAsReadSuccess:
          items.add(
              _DisplayItem.aiResponse('好的，我已经把刚才总结过的未读消息全部标为已读了，不过已读的消息还在哦！'));
          break;
        case _InteractionStep.aiMarkAsReadFailure:
          items.add(_DisplayItem.aiResponse('对不起，我试着标为已读失败了，您可以再试一下！'));
          break;
      }
    }

    return items;
  }

  Widget _buildListItem(_DisplayItem item) {
    switch (item.type) {
      case _DisplayItemType.dateHeader:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: Text(
              item.dateHeader!,
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );

      case _DisplayItemType.message:
        final msg = item.message!;
        return MessageBubble(
          senderName: msg.author ?? 'Aimi',
          message: msg.intro ?? msg.title ?? '',
          isRead: msg.isRead,
          maxLines: 3,
          showArrow: msg.content != null && msg.content!.isNotEmpty,
          onTap: () {
            // TODO: Navigate to message detail
          },
        );

      case _DisplayItemType.userMessage:
        return MessageBubble(
          senderName: '我', // Me
          message: item.userMessageText!,
          isUser: true,
          avatarUrl: '', // Could provide user avatar URL here
        );

      case _DisplayItemType.summaryPrompt:
        final promptText = item.categoryName!.isEmpty
            ? '您当前共有${item.unreadCount}条未读消息，如果需要我帮您总结未读消息的内容概要，请点击'
            : '"${item.categoryName}"栏目当前有${item.unreadCount}条未读消息，如果需要我帮您总结未读消息的内容概要，请点击';
        return MessageBubble(
          senderName: 'Aimi',
          message: promptText,
          actionWidget: AiSummaryButton(
            onTap: _onTriggerAiSummary,
            isLoading: false, // Loading is now a separate step
          ),
        );

      case _DisplayItemType.summaryResult:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary content bubble
            MessageBubble(
              senderName: 'Aimi',
              message: item.summaryText!, // This is the streamed content
            ),
            // Footer (Disclaimer + Feedback) - ONLY show if not loading?
            // The result item is added even during streaming.
            // But we might want to hide footer until done?
            // Current logic shows it always attached. Let's keep it simple.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 64, vertical: 4),
              child: Text(
                '免责声明：以上内容仅供参考，不作为投资依据。',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 11,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 8),
              child: Row(
                children: [
                  _buildFeedbackButton(Icons.thumb_up_outlined, '有用'),
                  const SizedBox(width: 16),
                  _buildFeedbackButton(Icons.thumb_down_outlined, '没用'),
                ],
              ),
            ),
          ],
        );

      case _DisplayItemType.markAsReadAction:
        final btnText = '点击对上述已总结的${item.categoryName}未读消息全部标为已读';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AiActionButton(
              text: btnText,
              onTap: _onMarkAsRead,
            ),
          ),
        );

      case _DisplayItemType.aiResponse:
        return MessageBubble(
          senderName: 'Aimi',
          message: item.responseText!,
        );
    }
  }

  Widget _buildFeedbackButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('感谢您的反馈：$label'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF232232),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF999999)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Smart time formatting based on design spec
  String _formatSmartTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(dt.year, dt.month, dt.day);
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (msgDate == today) {
      return time;
    } else if (msgDate == yesterday) {
      return '昨天 $time';
    } else if (dt.year == now.year) {
      return '${dt.month}月${dt.day}日 $time';
    } else {
      return '${dt.year}年${dt.month}月${dt.day}日 $time';
    }
  }
}

enum _InteractionStep {
  userRequestSummary,
  aiSummaryLoading,
  aiSummaryResult,
  aiMarkAsReadAction,
  userMarkAsRead,
  aiMarkAsReadSuccess,
  aiMarkAsReadFailure,
}

enum _DisplayItemType {
  dateHeader,
  message,
  userMessage,
  summaryPrompt,
  summaryResult,
  markAsReadAction,
  aiResponse,
}

class _DisplayItem {
  final _DisplayItemType type;
  final String? dateHeader;
  final MessageItem? message;
  final int? unreadCount;
  final String? summaryText;
  final String? categoryName;
  final String? responseText;
  final String? userMessageText;

  _DisplayItem._({
    required this.type,
    this.dateHeader,
    this.message,
    this.unreadCount,
    this.summaryText,
    this.categoryName,
    this.responseText,
    this.userMessageText,
  });

  factory _DisplayItem.dateHeader(String date) =>
      _DisplayItem._(type: _DisplayItemType.dateHeader, dateHeader: date);

  factory _DisplayItem.message(MessageItem msg) =>
      _DisplayItem._(type: _DisplayItemType.message, message: msg);

  factory _DisplayItem.userMessage(String text) =>
      _DisplayItem._(type: _DisplayItemType.userMessage, userMessageText: text);

  factory _DisplayItem.summaryPrompt(int count, String categoryName) =>
      _DisplayItem._(
        type: _DisplayItemType.summaryPrompt,
        unreadCount: count,
        categoryName: categoryName,
      );

  factory _DisplayItem.summaryResult(String text, String categoryName) =>
      _DisplayItem._(
        type: _DisplayItemType.summaryResult,
        summaryText: text,
        categoryName: categoryName,
      );

  factory _DisplayItem.markAsReadAction(String categoryName) => _DisplayItem._(
        type: _DisplayItemType.markAsReadAction,
        categoryName: categoryName,
      );

  factory _DisplayItem.aiResponse(String text) =>
      _DisplayItem._(type: _DisplayItemType.aiResponse, responseText: text);
}
