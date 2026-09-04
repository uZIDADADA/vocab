import 'package:flutter/material.dart';

import '../../application/coach/coach_controller.dart';
import '../../data/repositories/ai_settings_repository.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/learning_repository.dart';
import '../../domain/coach_models.dart';
import '../../infrastructure/ai/ai_chat_provider.dart';
import '../../theme/vocab_theme.dart';
import '../../widgets/vocab_ui.dart';

class CoachView extends StatefulWidget {
  const CoachView({
    required this.settingsRepository,
    required this.conversationRepository,
    required this.learningRepository,
    required this.provider,
    super.key,
  });

  final AiSettingsRepository settingsRepository;
  final ConversationRepository conversationRepository;
  final LearningRepository learningRepository;
  final AiChatProvider provider;

  @override
  State<CoachView> createState() => _CoachViewState();
}

class _CoachViewState extends State<CoachView> {
  late final CoachController _controller = CoachController(
    widget.settingsRepository,
    widget.conversationRepository,
    widget.provider,
  );
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller
      ..addListener(_scheduleScrollToBottom)
      ..initialize();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_scheduleScrollToBottom)
      ..dispose();
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<bool> _openSettings() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: VocabColors.surface,
      builder: (context) => _AiSettingsSheet(controller: _controller),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('AI 设置已保存在本机')));
    }
    return saved == true;
  }

  Future<void> _sendMessage() async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _controller.isSending) return;

    if (!_controller.settings.isConfigured) {
      final saved = await _openSettings();
      if (!saved || !_controller.settings.isConfigured) return;
    }

    _composerController.clear();
    await _controller.send(text);
  }

  Future<void> _openHistory() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: VocabColors.surface,
      builder: (context) => _ConversationHistorySheet(controller: _controller),
    );
  }

  Future<void> _extractMessage(CoachMessage message) async {
    if (!_controller.settings.isConfigured) {
      final saved = await _openSettings();
      if (!saved) return;
    }
    final suggestions = await _controller.extractLearningItems(message);
    if (!mounted || suggestions == null) return;
    if (suggestions.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('这条消息里没有识别出适合收藏的词句')));
      return;
    }
    final selected = suggestions.toSet();
    final confirmed = await showModalBottomSheet<List<CoachLearningSuggestion>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: VocabColors.surface,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '确认收藏到词句库',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 5),
                const Text(
                  '取消勾选不需要的内容；已存在的词句会自动跳过。',
                  style: TextStyle(color: VocabColors.muted),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selected.contains(suggestion),
                        title: Text(suggestion.text),
                        subtitle: Text(
                          '${suggestion.kind == CoachLearningKind.word ? '单词' : '句式'} · ${suggestion.meaning}',
                        ),
                        onChanged: (checked) => setSheetState(() {
                          if (checked == true) {
                            selected.add(suggestion);
                          } else {
                            selected.remove(suggestion);
                          }
                        }),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(context, selected.toList()),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text('收藏 ${selected.length} 项'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == null || confirmed.isEmpty) return;
    final savedCount = await widget.learningRepository.saveCoachSuggestions(
      confirmed,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已收藏 $savedCount 项，重复内容已跳过')));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final settings = _controller.settings;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                children: [
                  VocabPageHeader(
                    title: 'AI 口语教练',
                    subtitle: '先用文字热身，把想表达的话真正说自然。',
                    actions: [
                      RoundActionButton(
                        icon: Icons.history_rounded,
                        tooltip: '历史对话',
                        onPressed: _openHistory,
                      ),
                      const SizedBox(width: 8),
                      RoundActionButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'AI 设置',
                        onPressed: _openSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      StatusPill(
                        label: settings.config.displayName,
                        color: VocabColors.surface,
                        icon: Icons.hub_outlined,
                      ),
                      const Spacer(),
                      StatusPill(
                        label: settings.isConfigured ? '文本模式 · 已配置' : '等待配置',
                        color: settings.isConfigured
                            ? VocabColors.limeSoft
                            : VocabColors.coralSoft,
                        foreground: settings.isConfigured
                            ? VocabColors.green
                            : VocabColors.coralInk,
                        icon: settings.isConfigured
                            ? Icons.check_circle_outline_rounded
                            : Icons.key_rounded,
                      ),
                    ],
                  ),
                  if (settings.isConfigured) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        settings.config.model,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: VocabColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!_controller.isInitializing && !settings.isConfigured)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _SetupCard(onPressed: _openSettings),
              ),
            Expanded(
              child: _Conversation(
                controller: _scrollController,
                messages: _controller.messages,
                isSending: _controller.isSending,
                isExtracting: _controller.isExtracting,
                errorMessage: _controller.errorMessage,
                onExtract: _extractMessage,
              ),
            ),
            _Composer(
              controller: _composerController,
              enabled: !_controller.isInitializing && !_controller.isSending,
              isSending: _controller.isSending,
              onSend: _sendMessage,
              onClear: () => _controller.newConversation(),
            ),
          ],
        );
      },
    );
  }
}

class _ConversationHistorySheet extends StatefulWidget {
  const _ConversationHistorySheet({required this.controller});

  final CoachController controller;

  @override
  State<_ConversationHistorySheet> createState() =>
      _ConversationHistorySheetState();
}

class _ConversationHistorySheetState extends State<_ConversationHistorySheet> {
  late final TextEditingController _limitController = TextEditingController(
    text: '${widget.controller.retentionLimit}',
  );
  bool _isSaving = false;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _saveLimit() async {
    final value = int.tryParse(_limitController.text.trim());
    if (value == null ||
        value < ConversationRepository.minRetentionLimit ||
        value > ConversationRepository.maxRetentionLimit) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入 1–100 之间的会话数量')));
      return;
    }
    setState(() => _isSaving = true);
    final saved = await widget.controller.updateRetentionLimit(value);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('最多保留 $value 个对话')));
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空全部对话？'),
        content: const Text('聊天记录将从本机删除；已经保存的单词和句式不会受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.controller.clearAllConversations();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '历史对话',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.controller.isSending ? null : _clearAll,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('清空'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '最多保留会话数（1–100）',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveLimit,
                    child: Text(_isSaving ? '保存中…' : '保存'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.controller.conversations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final conversation = widget.controller.conversations[index];
                    final selected =
                        conversation.id ==
                        widget.controller.currentConversationId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      selected: selected,
                      leading: Icon(
                        selected
                            ? Icons.chat_bubble_rounded
                            : Icons.chat_bubble_outline_rounded,
                      ),
                      title: Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _formatConversationTime(conversation.updatedAt),
                      ),
                      onTap: () async {
                        await widget.controller.openConversation(
                          conversation.id,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      trailing: IconButton(
                        tooltip: '删除对话',
                        onPressed: widget.controller.isSending
                            ? null
                            : () => widget.controller.deleteConversation(
                                conversation.id,
                              ),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatConversationTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: VocabColors.cyanSoft,
      borderColor: VocabColors.cyan,
      child: Row(
        children: [
          const CircleIcon(
            icon: Icons.key_rounded,
            background: VocabColors.surface,
            foreground: VocabColors.cyan,
            size: 42,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '配置 Gemini 后开始对话',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'API Key 只写入设备安全存储，不进入 SQLite。',
                  style: TextStyle(fontSize: 11, color: VocabColors.muted),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onPressed, child: const Text('去设置')),
        ],
      ),
    );
  }
}

class _Conversation extends StatelessWidget {
  const _Conversation({
    required this.controller,
    required this.messages,
    required this.isSending,
    required this.isExtracting,
    required this.errorMessage,
    required this.onExtract,
  });

  final ScrollController controller;
  final List<CoachMessage> messages;
  final bool isSending;
  final bool isExtracting;
  final String? errorMessage;
  final ValueChanged<CoachMessage> onExtract;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const PageStorageKey('coach-conversation'),
      controller: controller,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      itemCount:
          messages.length +
          (isSending ? 1 : 0) +
          (errorMessage != null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final message = messages[index];
          return message.role == CoachRole.user
              ? _UserBubble(
                  text: message.text,
                  onExtract: isExtracting ? null : () => onExtract(message),
                )
              : _AssistantBubble(
                  text: message.text,
                  onExtract: isExtracting ? null : () => onExtract(message),
                );
        }
        if (isSending && index == messages.length) {
          return const _TypingBubble();
        }
        return _ErrorBubble(message: errorMessage!);
      },
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text, required this.onExtract});

  final String text;
  final VoidCallback? onExtract;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: const BoxDecoration(
          color: VocabColors.limeSoft,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SelectableText(text, style: Theme.of(context).textTheme.bodyLarge),
            _ExtractButton(onPressed: onExtract),
          ],
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text, required this.onExtract});

  final String text;
  final VoidCallback? onExtract;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              _ExtractButton(onPressed: onExtract),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtractButton extends StatelessWidget {
  const _ExtractButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.only(top: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.auto_awesome_outlined, size: 15),
      label: const Text('整理词句', style: TextStyle(fontSize: 11)),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: SoftCard(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SoftCard(
        color: VocabColors.coralSoft,
        borderColor: VocabColors.coral,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: VocabColors.coral),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: VocabColors.coralInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.isSending,
    required this.onSend,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: VocabColors.surface,
        border: Border(top: BorderSide(color: VocabColors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: enabled ? onClear : null,
            tooltip: '新对话',
            icon: const Icon(Icons.add_comment_outlined),
            style: IconButton.styleFrom(
              side: const BorderSide(color: VocabColors.line),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: '输入英文或中文开始陪练',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: enabled ? onSend : null,
            tooltip: '发送',
            icon: Icon(
              isSending ? Icons.hourglass_top_rounded : Icons.send_rounded,
            ),
            style: IconButton.styleFrom(
              backgroundColor: VocabColors.lime,
              foregroundColor: VocabColors.ink,
              disabledBackgroundColor: VocabColors.softSurface,
              minimumSize: const Size.square(52),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSettingsSheet extends StatefulWidget {
  const _AiSettingsSheet({required this.controller});

  final CoachController controller;

  @override
  State<_AiSettingsSheet> createState() => _AiSettingsSheetState();
}

class _AiSettingsSheetState extends State<_AiSettingsSheet> {
  late AiProviderKind _kind = widget.controller.settings.config.kind;
  late final TextEditingController _baseUrlController = TextEditingController(
    text: widget.controller.settings.config.baseUrl,
  );
  late final TextEditingController _modelController = TextEditingController(
    text: widget.controller.settings.config.model,
  );
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _changeKind(AiProviderKind? value) {
    if (value == null || value == _kind) return;
    setState(() {
      _kind = value;
      if (value == AiProviderKind.gemini) {
        const defaults = AiProviderConfig.gemini();
        _baseUrlController.text = defaults.baseUrl;
        _modelController.text = defaults.model;
      } else {
        _baseUrlController.text = 'https://api.openai.com/v1';
        _modelController.clear();
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final saved = await widget.controller.saveSettings(
      AiProviderConfig(
        kind: _kind,
        baseUrl: _baseUrlController.text,
        model: _modelController.text,
      ),
      replacementApiKey: _apiKeyController.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedKey = widget.controller.settings.apiKey?.isNotEmpty == true;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: VocabColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('AI 服务设置', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 5),
            const Text(
              '首版使用 OpenAI 兼容协议。Gemini 和多数兼容模型可以共用同一套聊天实现。',
              style: TextStyle(color: VocabColors.muted),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<AiProviderKind>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: '提供商预设'),
              items: AiProviderKind.values
                  .map(
                    (kind) =>
                        DropdownMenuItem(value: kind, child: Text(kind.label)),
                  )
                  .toList(growable: false),
              onChanged: _isSaving ? null : _changeKind,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _baseUrlController,
              enabled: !_isSaving,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://…/v1',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              enabled: !_isSaving,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: '模型名称',
                hintText: 'gemini-3.1-flash-lite',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              enabled: !_isSaving,
              obscureText: _obscureKey,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: hasSavedKey ? '已保存；留空表示不修改' : '首次配置必须填写',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  icon: Icon(
                    _obscureKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 17,
                  color: VocabColors.green,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '密钥保存在系统安全存储中；聊天内容会发送到你选择的 AI 服务。',
                    style: TextStyle(fontSize: 11, color: VocabColors.muted),
                  ),
                ),
              ],
            ),
            if (widget.controller.errorMessage case final message?) ...[
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(color: VocabColors.coralInk),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? '保存中…' : '保存设置'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
