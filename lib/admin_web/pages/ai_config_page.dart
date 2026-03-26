import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:app/models/ai_runtime_config.dart';
import 'package:app/services/ai_service.dart';
import 'package:app/services/transaction_phrase_lexicon.dart';
import 'package:flutter/material.dart';

class AiConfigPage extends StatefulWidget {
  const AiConfigPage({
    super.key,
    required this.repository,
    required this.profile,
  });

  final AdminWebRepository repository;
  final AdminProfile profile;

  @override
  State<AiConfigPage> createState() => _AiConfigPageState();
}

class _AiConfigPageState extends State<AiConfigPage> {
  final AIService _aiService = AIService();
  final TextEditingController _previewInputController = TextEditingController(
    text: 'ăn phở 45k và đổ xăng 100k',
  );
  final TextEditingController _runtimePreviewInputController =
      TextEditingController(
        text: 'ăn trưa 45k, nếu chưa đủ thì hỏi lại đúng phần còn thiếu',
      );
  final TextEditingController _providerController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _rolePromptController = TextEditingController();
  final TextEditingController _taskPromptController = TextEditingController();
  final TextEditingController _cardRulesPromptController =
      TextEditingController();
  final TextEditingController _conversationRulesPromptController =
      TextEditingController();
  final TextEditingController _abbreviationRulesPromptController =
      TextEditingController();

  List<_LexiconSection> _sections = <_LexiconSection>[];
  String _draftRaw = '';
  int _publishedVersion = 1;
  int _draftVersion = 1;
  String _source = 'data.text';

  AiRuntimeConfig _publishedRuntimeConfig = AiRuntimeConfig.defaults();
  AiRuntimeConfig _draftRuntimeConfig = AiRuntimeConfig.defaults();
  int _publishedRuntimeVersion = 1;
  int _draftRuntimeVersion = 1;
  String _runtimeSource = 'Mặc định hệ thống';

  bool _runtimeEnabled = false;
  String _fallbackPolicy = 'local_parse';
  String _imageStrategy = 'ocr_then_ai';
  bool _loading = true;
  bool _savingDraft = false;
  bool _pushing = false;
  bool _previewLoading = false;
  bool _savingRuntimeDraft = false;
  bool _pushingRuntime = false;
  bool _runtimePreviewLoading = false;
  bool _showApiKey = false;

  String? _message;
  String? _previewMessage;
  Map<String, dynamic>? _previewResult;
  String? _runtimeMessage;
  String? _runtimePreviewMessage;
  Map<String, dynamic>? _runtimePreviewResult;

  bool get _hasUnsavedChanges => _buildRaw().trim() != _draftRaw.trim();
  bool get _runtimeHasUnsavedChanges =>
      !_isSameRuntimeConfig(_buildDraftRuntimeConfig(), _draftRuntimeConfig);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _previewInputController.dispose();
    _runtimePreviewInputController.dispose();
    _providerController.dispose();
    _modelController.dispose();
    _endpointController.dispose();
    _apiKeyController.dispose();
    _rolePromptController.dispose();
    _taskPromptController.dispose();
    _cardRulesPromptController.dispose();
    _conversationRulesPromptController.dispose();
    _abbreviationRulesPromptController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait<dynamic>([
      widget.repository.loadAiLexiconState(),
      widget.repository.loadAiRuntimeConfigState(),
    ]);

    final lexiconState = results[0] as AiLexiconState;
    final runtimeState = results[1] as AiRuntimeConfigState;
    final editableRaw = lexiconState.draftRaw.trim().isNotEmpty
        ? lexiconState.draftRaw
        : lexiconState.raw;

    _syncRuntimeEditors(runtimeState.draft);

    if (!mounted) return;
    setState(() {
      _draftRaw = editableRaw;
      _publishedVersion = lexiconState.version;
      _draftVersion = lexiconState.draftRaw.trim().isNotEmpty
          ? lexiconState.draftVersion
          : lexiconState.version;
      _source = lexiconState.sourceLabel;
      _sections = _parseSections(editableRaw);
      _publishedRuntimeConfig = runtimeState.published;
      _draftRuntimeConfig = runtimeState.draft;
      _publishedRuntimeVersion = runtimeState.publishedVersion;
      _draftRuntimeVersion = runtimeState.draftVersion;
      _runtimeSource = runtimeState.sourceLabel;
      _loading = false;
      _message = null;
      _previewMessage = null;
      _previewResult = null;
      _runtimeMessage = null;
      _runtimePreviewMessage = null;
      _runtimePreviewResult = null;
    });
  }

  void _syncRuntimeEditors(AiRuntimeConfig config) {
    _runtimeEnabled = config.enabled;
    _fallbackPolicy = config.fallbackPolicy;
    _imageStrategy = config.imageStrategy;
    _providerController.text = config.provider;
    _modelController.text = config.model;
    _endpointController.text = config.endpoint;
    _apiKeyController.text = config.apiKey;
    _rolePromptController.text = config.rolePrompt;
    _taskPromptController.text = config.taskPrompt;
    _cardRulesPromptController.text = config.cardRulesPrompt;
    _conversationRulesPromptController.text = config.conversationRulesPrompt;
    _abbreviationRulesPromptController.text = config.abbreviationRulesPrompt;
  }

  AiRuntimeConfig _buildDraftRuntimeConfig() {
    return AiRuntimeConfig(
      enabled: _runtimeEnabled,
      provider: _providerController.text.trim(),
      model: _modelController.text.trim(),
      endpoint: _endpointController.text.trim(),
      fallbackPolicy: _fallbackPolicy,
      imageStrategy: _imageStrategy,
      rolePrompt: _rolePromptController.text.trim(),
      taskPrompt: _taskPromptController.text.trim(),
      cardRulesPrompt: _cardRulesPromptController.text.trim(),
      conversationRulesPrompt: _conversationRulesPromptController.text.trim(),
      abbreviationRulesPrompt: _abbreviationRulesPromptController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );
  }

  bool _isSameRuntimeConfig(AiRuntimeConfig left, AiRuntimeConfig right) {
    final leftMap = left.toMap();
    final rightMap = right.toMap();
    for (final key in leftMap.keys) {
      if ('${leftMap[key]}' != '${rightMap[key]}') {
        return false;
      }
    }
    return true;
  }

  String _buildRaw() {
    return _sections
        .where(
          (section) =>
              section.key.trim().isNotEmpty && section.values.isNotEmpty,
        )
        .map((section) => '${section.key}::${section.values.join(',')}')
        .join('\n');
  }

  List<_LexiconSection> _parseSections(String raw) {
    final sections = <_LexiconSection>[];
    for (final rawLine in raw.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separator = line.contains('::') ? '::' : ':';
      if (!line.contains(separator)) continue;
      final separatorIndex = line.indexOf(separator);
      final key = line.substring(0, separatorIndex).trim().toUpperCase();
      final values = line.substring(separatorIndex + separator.length).trim();
      if (key.isEmpty || values.isEmpty) continue;
      sections.add(_LexiconSection(key: key, values: _parseValues(values)));
    }
    return sections;
  }

  List<String> _parseValues(String raw) {
    return raw
        .split(RegExp(r'[\n,]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _importFile() async {
    final controller = TextEditingController();
    String? importedRaw;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập nội dung tệp AI'),
        content: SizedBox(
          width: 720,
          child: TextField(
            controller: controller,
            minLines: 16,
            maxLines: 22,
            decoration: const InputDecoration(
              hintText: 'Dán nội dung data.text hoặc tệp txt vào đây...',
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              importedRaw = value;
              Navigator.of(context).pop();
            },
            child: const Text('Nhập'),
          ),
        ],
      ),
    );
    final raw = importedRaw;
    if (raw == null || raw.isEmpty || !mounted) return;
    setState(() {
      _sections = _parseSections(raw);
      _message = 'Đã nạp nội dung AI và tách các nhóm dữ liệu.';
    });
  }

  Future<void> _saveDraft() async {
    setState(() {
      _savingDraft = true;
      _message = null;
    });
    try {
      final raw = _buildRaw();
      await widget.repository.saveAiLexiconDraft(
        raw: raw,
        actor: widget.profile,
        nextVersion: _draftVersion + 1,
      );
      if (!mounted) return;
      setState(() {
        _draftRaw = raw;
        _draftVersion += 1;
        _message = 'Đã lưu nháp cấu hình AI.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingDraft = false;
        });
      }
    }
  }

  Future<void> _pushLive() async {
    setState(() {
      _pushing = true;
      _message = null;
    });
    try {
      final raw = _buildRaw();
      await widget.repository.saveAiLexiconDraft(
        raw: raw,
        actor: widget.profile,
        nextVersion: _draftVersion + 1,
      );
      await widget.repository.saveAiLexiconRaw(
        raw: raw,
        actor: widget.profile,
        nextVersion: _publishedVersion + 1,
      );
      if (!mounted) return;
      setState(() {
        _draftRaw = raw;
        _draftVersion += 1;
        _publishedVersion += 1;
        _source = 'Cấu hình Firestore';
        _message = 'Đã đẩy cấu hình AI lên bản đang hoạt động.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _pushing = false;
        });
      }
    }
  }

  Future<void> _saveRuntimeDraft() async {
    setState(() {
      _savingRuntimeDraft = true;
      _runtimeMessage = null;
    });
    try {
      final next = _buildDraftRuntimeConfig();
      await widget.repository.saveAiRuntimeConfigDraft(
        config: next,
        actor: widget.profile,
        nextVersion: _draftRuntimeVersion + 1,
      );
      if (!mounted) return;
      setState(() {
        _draftRuntimeConfig = next;
        _draftRuntimeVersion += 1;
        _runtimeMessage = 'Đã lưu nháp runtime AI.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingRuntimeDraft = false;
        });
      }
    }
  }

  Future<void> _pushRuntimeLive() async {
    setState(() {
      _pushingRuntime = true;
      _runtimeMessage = null;
    });
    try {
      final next = _buildDraftRuntimeConfig();
      await widget.repository.saveAiRuntimeConfigDraft(
        config: next,
        actor: widget.profile,
        nextVersion: _draftRuntimeVersion + 1,
      );
      await widget.repository.saveAiRuntimeConfigRaw(
        config: next,
        actor: widget.profile,
        nextVersion: _publishedRuntimeVersion + 1,
      );
      if (!mounted) return;
      setState(() {
        _draftRuntimeConfig = next;
        _publishedRuntimeConfig = next;
        _draftRuntimeVersion += 1;
        _publishedRuntimeVersion += 1;
        _runtimeSource = 'Runtime Firestore';
        _runtimeMessage = 'Đã đẩy runtime AI lên bản đang hoạt động.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _pushingRuntime = false;
        });
      }
    }
  }

  Future<void> _runPreview() async {
    final input = _previewInputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _previewMessage = 'Nhập một câu giao dịch để xem trước.';
      });
      return;
    }
    setState(() {
      _previewLoading = true;
      _previewMessage = null;
    });
    try {
      final raw = _buildRaw();
      TransactionPhraseLexicon.setSessionOverride(raw);
      final result = await _aiService.processInput(input);
      if (!mounted) return;
      setState(() {
        _previewResult = result;
        _previewMessage = 'Đã phân tích với bản nháp local parse hiện tại.';
      });
    } finally {
      TransactionPhraseLexicon.clearSessionOverride();
      if (mounted) {
        setState(() {
          _previewLoading = false;
        });
      }
    }
  }

  Future<void> _runRuntimePreview() async {
    final input = _runtimePreviewInputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _runtimePreviewMessage = 'Nhập một câu để xem trước runtime AI.';
      });
      return;
    }
    setState(() {
      _runtimePreviewLoading = true;
      _runtimePreviewMessage = null;
    });
    try {
      final result = await _aiService.processInput(
        input,
        runtimeOverride: _buildDraftRuntimeConfig(),
      );
      if (!mounted) return;
      setState(() {
        _runtimePreviewResult = result;
        _runtimePreviewMessage =
            'Đã xem trước bằng bản nháp runtime AI. Bản chạy hiện tại không bị thay đổi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _runtimePreviewLoading = false;
        });
      }
    }
  }

  Future<void> _showSectionDialog({
    _LexiconSection? section,
    int? index,
  }) async {
    final keyController = TextEditingController(text: section?.key ?? '');
    final valuesController = TextEditingController(
      text: section == null ? '' : section.values.join(', '),
    );
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                section == null ? 'Thêm nhóm dữ liệu' : 'Sửa nhóm dữ liệu',
              ),
              content: SizedBox(
                width: 620,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: 'Mã nhóm',
                        hintText: 'Ví dụ: TYPE_CREDIT, AN_UONG...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: valuesController,
                      minLines: 8,
                      maxLines: 14,
                      decoration: const InputDecoration(
                        labelText: 'Danh sách từ khóa',
                        hintText: 'Cách nhau bởi dấu phẩy hoặc xuống dòng',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: Color(0xFFD92D20),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () {
                    final key = keyController.text.trim().toUpperCase();
                    final values = _parseValues(valuesController.text);
                    if (key.isEmpty) {
                      setDialogState(() {
                        errorText = 'Mã nhóm không được để trống.';
                      });
                      return;
                    }
                    if (values.isEmpty) {
                      setDialogState(() {
                        errorText = 'Cần ít nhất 1 từ khóa.';
                      });
                      return;
                    }
                    setState(() {
                      final next = _LexiconSection(key: key, values: values);
                      if (index == null) {
                        _sections = <_LexiconSection>[..._sections, next];
                      } else {
                        final copied = [..._sections];
                        copied[index] = next;
                        _sections = copied;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSystemFileDialog(String raw) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tệp hệ thống AI'),
        content: SizedBox(
          width: 760,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đây là tệp hệ thống đại diện cho cấu hình gốc. Tệp này chỉ để xem đối chiếu, không sửa trực tiếp và không được xóa để tránh mất chức năng AI.',
                style: TextStyle(
                  color: Color(0xFF667085),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 420),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    raw,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final raw = _buildRaw();
    final lexicon = TransactionPhraseLexicon.parseRaw(raw);
    final groups = _buildSummaryGroups(lexicon);
    final runtimeDraft = _buildDraftRuntimeConfig();

    return ListView(
      children: [
        Wrap(
          runSpacing: 14,
          spacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 560,
              child: Text(
                'Cấu hình AI được tách thành local parse và runtime AI thật. Chỉnh sửa runtime sẽ không làm thay đổi bộ từ điển parse hiện tại.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            AdminRolePill(label: 'Từ điển v$_publishedVersion'),
            AdminRolePill(label: 'runtime v$_publishedRuntimeVersion'),
            AdminRolePill(label: _runtimeSource),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: groups
              .map(
                (group) =>
                    SizedBox(width: 240, child: _SummaryCard(group: group)),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        _buildRuntimeConfigPanel(runtimeDraft),
        const SizedBox(height: 18),
        _buildLexiconPanel(),
        const SizedBox(height: 18),
        _buildLocalPreviewPanel(),
        const SizedBox(height: 18),
        _buildRuntimePreviewPanel(),
        const SizedBox(height: 18),
        AdminPanel(
          title: 'Tệp hệ thống',
          isExpanded: false,
          child: _SystemFileCard(
            source: _source,
            raw: raw,
            onView: () => _showSystemFileDialog(raw),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRuntimeConfigPanel(AiRuntimeConfig runtimeDraft) {
    return AdminPanel(
      title: 'Cấu hình runtime AI thật',
      isExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminRolePill(label: 'ban chay v$_publishedRuntimeVersion'),
              AdminRolePill(label: 'ban nhap v$_draftRuntimeVersion'),
              _CountPill(
                label: runtimeDraft.enabled ? 'AI that: bat' : 'AI that: tat',
              ),
              _CountPill(
                label: runtimeDraft.hasApiKey
                    ? 'API key: ${runtimeDraft.maskedApiKey}'
                    : 'API key: chua co',
              ),
            ],
          ),
          if (_runtimeMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDDEEE6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _runtimeMessage!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _runtimeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _runtimeEnabled = value;
                    });
                  },
                  title: const Text(
                    'Bat che do AI that',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Khi bat, app se uu tien runtime AI neu key va config hop le.',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _providerController,
                        decoration: const InputDecoration(
                          labelText: 'Nhà cung cấp',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _modelController,
                        decoration: const InputDecoration(labelText: 'Mô hình'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _endpointController,
                  decoration: const InputDecoration(labelText: 'Điểm cuối API'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _fallbackPolicy,
                        decoration: const InputDecoration(
                          labelText: 'Chính sách dự phòng',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'local_parse',
                            child: Text('local_parse'),
                          ),
                          DropdownMenuItem(
                            value: 'strict_remote',
                            child: Text('strict_remote'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _fallbackPolicy = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _imageStrategy,
                        decoration: const InputDecoration(
                          labelText: 'Chiến lược ảnh',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'ai_then_ocr',
                            child: Text('ai_then_ocr'),
                          ),
                          DropdownMenuItem(
                            value: 'ocr_then_ai',
                            child: Text('ocr_then_ai'),
                          ),
                          DropdownMenuItem(
                            value: 'ocr_only',
                            child: Text('ocr_only'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _imageStrategy = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  obscureText: !_showApiKey,
                  decoration: InputDecoration(
                    labelText: 'Khóa API Groq',
                    helperText: runtimeDraft.hasApiKey
                        ? 'Key hien tai: ${runtimeDraft.maskedApiKey}'
                        : 'Chua co key runtime',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showApiKey = !_showApiKey;
                            });
                          },
                          icon: Icon(
                            _showApiKey
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _apiKeyController.clear();
                            });
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 1: Vai trò',
            subtitle: 'Bản sắc chuyên môn và giọng nói của AI.',
            controller: _rolePromptController,
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 2: Nhiệm vụ',
            subtitle: 'Nhiệm vụ và cách phân loại ý định.',
            controller: _taskPromptController,
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 3: Quy tắc tạo thẻ',
            subtitle: 'Khi nào được tạo thẻ, khi nào phải hỏi lại.',
            controller: _cardRulesPromptController,
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 4: Quy tắc hội thoại',
            subtitle: 'Quy tắc trả lời tự nhiên cho ngữ cảnh rộng.',
            controller: _conversationRulesPromptController,
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 5: Viết tắt / Tiếng lóng / Địa phương',
            subtitle:
                'Chuan hoa viet tat, slang, cach noi doi thuong, va bien the dia phuong truoc khi suy luan nghiep vu.',
            controller: _abbreviationRulesPromptController,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (_runtimeHasUnsavedChanges)
                const Text(
                  'Runtime ban nhap co thay doi chua luu',
                  style: TextStyle(
                    color: Color(0xFFDC6803),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _syncRuntimeEditors(_publishedRuntimeConfig);
                    _runtimeMessage =
                        'Da khoi phuc runtime ban nhap theo ban dang hoat dong.';
                  });
                },
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Khôi phục bản chạy'),
              ),
              FilledButton.tonalIcon(
                onPressed: _savingRuntimeDraft ? null : _saveRuntimeDraft,
                icon: _savingRuntimeDraft
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu nháp runtime'),
              ),
              FilledButton.icon(
                onPressed: _pushingRuntime ? null : _pushRuntimeLive,
                icon: _pushingRuntime
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish_rounded),
                label: const Text('Đẩy runtime bản chạy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLexiconPanel() {
    return AdminPanel(
      title: 'Từ điển Local Parse',
      isExpanded: false,
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 12,
            spacing: 12,
            children: [
              Text(
                '${_sections.length} nhom',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_hasUnsavedChanges)
                const Text(
                  'Ban nhap co thay doi chua luu',
                  style: TextStyle(
                    color: Color(0xFFDC6803),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _importFile,
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Nhập tệp'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showSectionDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm nhóm'),
              ),
              FilledButton.tonalIcon(
                onPressed: _savingDraft ? null : _saveDraft,
                icon: _savingDraft
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu nháp'),
              ),
              FilledButton.icon(
                onPressed: _pushing ? null : _pushLive,
                icon: _pushing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish_rounded),
                label: const Text('Đẩy bản chạy'),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDDEEE6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _message!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_sections.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: Text('Chưa có nhóm dữ liệu nào.')),
            )
          else
            ..._sections.asMap().entries.map((entry) {
              final index = entry.key;
              final section = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _sections.length - 1 ? 0 : 12,
                ),
                child: _SectionCard(
                  section: section,
                  onEdit: () =>
                      _showSectionDialog(section: section, index: index),
                  onDelete: () {
                    setState(() {
                      _sections = _sections
                          .where((item) => item != section)
                          .toList(growable: false);
                    });
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLocalPreviewPanel() {
    return AdminPanel(
      title: 'Xem trước local parse',
      isExpanded: false,
      child: Column(
        children: [
          TextField(
            controller: _previewInputController,
            decoration: const InputDecoration(
              labelText: 'Nhập câu giao dịch để kiểm tra',
              hintText: 'Ví dụ: mẹ cho 2 triệu, mua trà sữa 45k',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _previewLoading ? null : _runPreview,
                icon: _previewLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.smart_toy_outlined),
                label: const Text('Phân tích'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _previewResult = null;
                    _previewMessage = null;
                  });
                },
                child: const Text('Xóa xem trước'),
              ),
            ],
          ),
          if (_previewMessage != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _previewMessage!,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          _PreviewResult(result: _previewResult),
        ],
      ),
    );
  }

  Widget _buildRuntimePreviewPanel() {
    return AdminPanel(
      title: 'Xem trước runtime AI',
      isExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bản xem trước này luôn dùng bản nháp runtime AI và không đổi bản chạy hiện tại.',
            style: TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _runtimePreviewInputController,
            decoration: const InputDecoration(
              labelText: 'Nhập câu để kiểm tra runtime AI',
              hintText: 'Ví dụ: tiền cafe này cho vào danh mục nào?',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _runtimePreviewLoading ? null : _runRuntimePreview,
                icon: _runtimePreviewLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology_alt_outlined),
                label: const Text('Xem trước runtime'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _runtimePreviewResult = null;
                    _runtimePreviewMessage = null;
                  });
                },
                child: const Text('Xóa xem trước'),
              ),
            ],
          ),
          if (_runtimePreviewMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _runtimePreviewMessage!,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _PreviewResult(result: _runtimePreviewResult),
        ],
      ),
    );
  }

  List<_SummaryGroup> _buildSummaryGroups(TransactionPhraseLexicon lexicon) {
    return <_SummaryGroup>[
      _SummaryGroup(
        label: 'Nhom danh muc',
        value: '${lexicon.categoryPhrases.length}',
        note: 'so nhom danh muc',
        tint: const Color(0xFF7A5AF8),
      ),
      _SummaryGroup(
        label: 'Tu khoa thu',
        value: '${lexicon.creditPhrases.length}',
        note: 'cum tu thu nhap',
        tint: const Color(0xFF039855),
      ),
      _SummaryGroup(
        label: 'Tu khoa chi',
        value: '${lexicon.debitPhrases.length}',
        note: 'cum tu chi tieu',
        tint: const Color(0xFFD92D20),
      ),
      _SummaryGroup(
        label: 'Quy tac uu tien',
        value: '${lexicon.prioritySections.length}',
        note: 'tu khoa -> danh muc',
        tint: const Color(0xFF155EEF),
      ),
      _SummaryGroup(
        label: 'Phu dinh',
        value: '${lexicon.negationPhrases.length}',
        note: 'bo loc huy',
        tint: const Color(0xFFDC6803),
      ),
      _SummaryGroup(
        label: 'Tuong lai / Cong no',
        value:
            '${lexicon.futureIntentPhrases.length + lexicon.debtIntentPhrases.length}',
        note: 'y dinh va cong no',
        tint: const Color(0xFF1E3A37),
      ),
    ];
  }
}

class _PromptEditorCard extends StatelessWidget {
  const _PromptEditorCard({
    required this.title,
    required this.subtitle,
    required this.controller,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 9,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.onEdit,
    required this.onDelete,
  });

  final _LexiconSection section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              _CountPill(label: '${section.values.length} từ'),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onEdit, child: const Text('Sửa')),
              const SizedBox(width: 8),
              FilledButton.tonal(onPressed: onDelete, child: const Text('Xóa')),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: section.values
                .take(24)
                .map(
                  (value) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PreviewResult extends StatelessWidget {
  const _PreviewResult({required this.result});

  final Map<String, dynamic>? result;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Chưa có kết quả xem trước.'),
      );
    }

    final transactions =
        (result!['transactions'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CountPill(
                    label: _statusLabel(result!['status']?.toString() ?? ''),
                  ),
                  _CountPill(
                    label: result!['responseKind']?.toString() ?? 'không rõ',
                  ),
                  _CountPill(label: '${transactions.length} giao dịch'),
                  _CountPill(
                    label: result!['source']?.toString() ?? 'không rõ',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                result!['message']?.toString() ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475467),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Không có giao dịch nào được tách ra.'),
          )
        else
          ...transactions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title']?.toString() ?? 'Không có tiêu đề',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          item['amount']?.toString() ?? '0',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: item['type'] == 'credit'
                                ? const Color(0xFF039855)
                                : const Color(0xFFD92D20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CountPill(
                          label:
                              'Loại: ${_typeLabel(item['type']?.toString() ?? '')}',
                        ),
                        _CountPill(
                          label: 'Danh mục: ${item['category'] ?? ''}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SystemFileCard extends StatelessWidget {
  const _SystemFileCard({
    required this.source,
    required this.raw,
    required this.onView,
  });

  final String source;
  final String raw;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(raw).length + 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_rounded, color: Color(0xFF155EEF)),
              SizedBox(width: 10),
              Text(
                'data.text / tệp đại diện hệ thống',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tệp này chỉ để đối chiếu và xem nội dung gốc.',
            style: const TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CountPill(label: 'Nguồn: $source'),
              _CountPill(label: '$lineCount dòng'),
              _CountPill(label: '${raw.length} ký tự'),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onView,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Xem tệp hệ thống'),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String value) {
  switch (value) {
    case 'success':
      return 'Thành công';
    case 'clarification':
      return 'Cần làm rõ';
    case 'error':
      return 'Lỗi';
    default:
      return value;
  }
}

String _typeLabel(String value) {
  switch (value) {
    case 'credit':
      return 'Thu';
    case 'debit':
      return 'Chi';
    default:
      return value;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.group});

  final _SummaryGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            group.label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            group.note,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF344054),
        ),
      ),
    );
  }
}

class _SummaryGroup {
  const _SummaryGroup({
    required this.label,
    required this.value,
    required this.note,
    required this.tint,
  });

  final String label;
  final String value;
  final String note;
  final Color tint;
}

class _LexiconSection {
  const _LexiconSection({required this.key, required this.values});

  final String key;
  final List<String> values;
}
