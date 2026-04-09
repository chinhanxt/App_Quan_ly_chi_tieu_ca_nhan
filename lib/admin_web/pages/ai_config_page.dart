import 'dart:async';

import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:app/models/ai_runtime_config.dart';
import 'package:app/services/ai_service.dart';
import 'package:app/services/transaction_phrase_lexicon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController _assistantPreviewInputController =
      TextEditingController(
        text: 'ngân sách tháng này của mình đang thế nào?',
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
  final TextEditingController _transactionSystemContractPromptController =
      TextEditingController();
  final TextEditingController _assistantProviderController =
      TextEditingController();
  final TextEditingController _assistantModelController = TextEditingController();
  final TextEditingController _assistantEndpointController =
      TextEditingController();
  final TextEditingController _assistantApiKeyController =
      TextEditingController();
  final TextEditingController _assistantRolePromptController =
      TextEditingController();
  final TextEditingController _assistantTaskPromptController =
      TextEditingController();
  final TextEditingController _assistantConversationRulesPromptController =
      TextEditingController();
  final TextEditingController _assistantAbbreviationRulesPromptController =
      TextEditingController();
  final TextEditingController _assistantAdvancedReasoningPromptController =
      TextEditingController();
  final TextEditingController _assistantMasterKnowledgePromptController =
      TextEditingController();
  final TextEditingController _assistantActionGuidePromptController =
      TextEditingController();
  final TextEditingController _assistantSystemContractPromptController =
      TextEditingController();

  List<_LexiconSection> _sections = <_LexiconSection>[];
  String _draftRaw = '';
  int _publishedVersion = 1;
  int _draftVersion = 1;
  String _source = 'data.text';
  int _selectedTabIndex = 0;

  AiRuntimeConfig _publishedRuntimeConfig = AiRuntimeConfig.defaults();
  AiRuntimeConfig _draftRuntimeConfig = AiRuntimeConfig.defaults();
  int _publishedRuntimeVersion = 1;
  int _draftRuntimeVersion = 1;
  int _publishedAssistantRuntimeVersion = 1;
  int _draftAssistantRuntimeVersion = 1;
  String _runtimeSource = 'Mặc định hệ thống';
  List<AiConfigVersionRecord> _runtimeHistory = const <AiConfigVersionRecord>[];
  List<AiConfigVersionRecord> _assistantRuntimeHistory =
      const <AiConfigVersionRecord>[];
  List<AiConfigVersionRecord> _lexiconHistory = const <AiConfigVersionRecord>[];

  bool _runtimeEnabled = false;
  bool _assistantRuntimeEnabled = false;
  String _fallbackPolicy = 'local_parse';
  String _imageStrategy = 'ocr_then_ai';
  bool _loading = true;
  bool _savingDraft = false;
  bool _pushing = false;
  bool _previewLoading = false;
  bool _savingRuntimeDraft = false;
  bool _pushingRuntime = false;
  bool _syncingRuntimeEnabled = false;
  bool _runtimePreviewLoading = false;
  bool _publishedRuntimeProbeLoading = false;
  bool _assistantPreviewLoading = false;
  bool _assistantPublishedProbeLoading = false;
  bool _rollingBackRuntime = false;
  bool _rollingBackLexicon = false;
  bool _showApiKey = false;
  bool _showAssistantApiKey = false;
  bool _editingTransactionRuntime = false;
  bool _editingAssistantRuntime = false;
  bool _editingParse = false;

  StreamSubscription<AiLexiconState>? _lexiconStateSubscription;
  StreamSubscription<AiRuntimeConfigState>? _runtimeStateSubscription;
  StreamSubscription<List<AiConfigVersionRecord>>? _runtimeHistorySubscription;
  StreamSubscription<AiRuntimeConfigState>? _assistantRuntimeStateSubscription;
  StreamSubscription<List<AiConfigVersionRecord>>?
      _assistantRuntimeHistorySubscription;
  StreamSubscription<List<AiConfigVersionRecord>>? _lexiconHistorySubscription;

  String? _message;
  String? _previewMessage;
  Map<String, dynamic>? _previewResult;
  String? _runtimeMessage;
  String? _runtimePreviewMessage;
  Map<String, dynamic>? _runtimePreviewResult;
  String? _publishedRuntimeProbeMessage;
  Map<String, dynamic>? _publishedRuntimeProbeResult;
  String? _assistantRuntimeMessage;
  String? _assistantPreviewMessage;
  Map<String, dynamic>? _assistantPreviewResult;
  String? _assistantPublishedProbeMessage;
  Map<String, dynamic>? _assistantPublishedProbeResult;

  bool get _hasUnsavedChanges => _buildRaw().trim() != _draftRaw.trim();
  bool get _runtimeHasUnsavedChanges =>
      !_isSameRuntimeConfig(_buildDraftRuntimeConfig(), _draftRuntimeConfig);

  @override
  void initState() {
    super.initState();
    _load();
    _bindRealtimeStreams();
  }

  @override
  void dispose() {
    _lexiconStateSubscription?.cancel();
    _runtimeStateSubscription?.cancel();
    _runtimeHistorySubscription?.cancel();
    _assistantRuntimeStateSubscription?.cancel();
    _assistantRuntimeHistorySubscription?.cancel();
    _lexiconHistorySubscription?.cancel();
    _previewInputController.dispose();
    _runtimePreviewInputController.dispose();
    _assistantPreviewInputController.dispose();
    _providerController.dispose();
    _modelController.dispose();
    _endpointController.dispose();
    _apiKeyController.dispose();
    _rolePromptController.dispose();
    _taskPromptController.dispose();
    _cardRulesPromptController.dispose();
    _conversationRulesPromptController.dispose();
    _abbreviationRulesPromptController.dispose();
    _transactionSystemContractPromptController.dispose();
    _assistantProviderController.dispose();
    _assistantModelController.dispose();
    _assistantEndpointController.dispose();
    _assistantApiKeyController.dispose();
    _assistantRolePromptController.dispose();
    _assistantTaskPromptController.dispose();
    _assistantConversationRulesPromptController.dispose();
    _assistantAbbreviationRulesPromptController.dispose();
    _assistantAdvancedReasoningPromptController.dispose();
    _assistantMasterKnowledgePromptController.dispose();
    _assistantActionGuidePromptController.dispose();
    _assistantSystemContractPromptController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait<dynamic>([
      widget.repository.loadAiLexiconState(),
      widget.repository.loadAiRuntimeConfigState(),
      widget.repository.loadAiAssistantRuntimeConfigState(),
    ]);

    final lexiconState = results[0] as AiLexiconState;
    final runtimeState = results[1] as AiRuntimeConfigState;
    final assistantRuntimeState = results[2] as AiRuntimeConfigState;
    final editableRaw = lexiconState.draftRaw.trim().isNotEmpty
        ? lexiconState.draftRaw
        : lexiconState.raw;
    final mergedDraftRuntime = runtimeState.draft.copyWith(
      assistantEnabled: assistantRuntimeState.draft.assistantEnabled,
      assistantProvider: assistantRuntimeState.draft.assistantProvider,
      assistantModel: assistantRuntimeState.draft.assistantModel,
      assistantEndpoint: assistantRuntimeState.draft.assistantEndpoint,
      assistantRolePrompt: assistantRuntimeState.draft.assistantRolePrompt,
      assistantTaskPrompt: assistantRuntimeState.draft.assistantTaskPrompt,
      assistantConversationRulesPrompt:
          assistantRuntimeState.draft.assistantConversationRulesPrompt,
      assistantAbbreviationRulesPrompt:
          assistantRuntimeState.draft.assistantAbbreviationRulesPrompt,
      assistantAdvancedReasoningPrompt:
          assistantRuntimeState.draft.assistantAdvancedReasoningPrompt,
      assistantMasterKnowledgePrompt:
          assistantRuntimeState.draft.assistantMasterKnowledgePrompt,
      assistantActionGuidePrompt:
          assistantRuntimeState.draft.assistantActionGuidePrompt,
      assistantSystemContractPrompt:
          assistantRuntimeState.draft.assistantSystemContractPrompt,
      assistantApiKey: assistantRuntimeState.draft.assistantApiKey,
    );
    final mergedPublishedRuntime = runtimeState.published.copyWith(
      assistantEnabled: assistantRuntimeState.published.assistantEnabled,
      assistantProvider: assistantRuntimeState.published.assistantProvider,
      assistantModel: assistantRuntimeState.published.assistantModel,
      assistantEndpoint: assistantRuntimeState.published.assistantEndpoint,
      assistantRolePrompt: assistantRuntimeState.published.assistantRolePrompt,
      assistantTaskPrompt: assistantRuntimeState.published.assistantTaskPrompt,
      assistantConversationRulesPrompt:
          assistantRuntimeState.published.assistantConversationRulesPrompt,
      assistantAbbreviationRulesPrompt:
          assistantRuntimeState.published.assistantAbbreviationRulesPrompt,
      assistantAdvancedReasoningPrompt:
          assistantRuntimeState.published.assistantAdvancedReasoningPrompt,
      assistantMasterKnowledgePrompt:
          assistantRuntimeState.published.assistantMasterKnowledgePrompt,
      assistantActionGuidePrompt:
          assistantRuntimeState.published.assistantActionGuidePrompt,
      assistantSystemContractPrompt:
          assistantRuntimeState.published.assistantSystemContractPrompt,
      assistantApiKey: assistantRuntimeState.published.assistantApiKey,
    );

    _syncRuntimeEditors(mergedDraftRuntime);

    if (!mounted) return;
    setState(() {
      _draftRaw = editableRaw;
      _publishedVersion = lexiconState.version;
      _draftVersion = lexiconState.draftRaw.trim().isNotEmpty
          ? lexiconState.draftVersion
          : lexiconState.version;
      _source = lexiconState.sourceLabel;
      _sections = _parseSections(editableRaw);
      _publishedRuntimeConfig = mergedPublishedRuntime;
      _draftRuntimeConfig = mergedDraftRuntime;
      _publishedRuntimeVersion = runtimeState.publishedVersion;
      _draftRuntimeVersion = runtimeState.draftVersion;
      _publishedAssistantRuntimeVersion = assistantRuntimeState.publishedVersion;
      _draftAssistantRuntimeVersion = assistantRuntimeState.draftVersion;
      _runtimeSource = runtimeState.sourceLabel;
      _loading = false;
      _message = null;
      _previewMessage = null;
      _previewResult = null;
      _runtimeMessage = null;
      _runtimePreviewMessage = null;
      _runtimePreviewResult = null;
      _publishedRuntimeProbeMessage = null;
      _publishedRuntimeProbeResult = null;
      _assistantRuntimeMessage = null;
      _assistantPreviewMessage = null;
      _assistantPreviewResult = null;
      _assistantPublishedProbeMessage = null;
      _assistantPublishedProbeResult = null;
    });
  }

  void _bindRealtimeStreams() {
    _lexiconStateSubscription = widget.repository
        .watchAiLexiconState()
        .listen((state) {
          if (!mounted) return;
          setState(() {
            _publishedVersion = state.version;
            _source = state.sourceLabel;
            if (!_hasUnsavedChanges) {
              final editableRaw = state.draftRaw.trim().isNotEmpty
                  ? state.draftRaw
                  : state.raw;
              _draftRaw = editableRaw;
              _draftVersion = state.draftRaw.trim().isNotEmpty
                  ? state.draftVersion
                  : state.version;
              _sections = _parseSections(editableRaw);
            }
          });
        });

    _runtimeStateSubscription = widget.repository
        .watchAiRuntimeConfigState()
        .listen((state) {
          if (!mounted) return;
          setState(() {
            _publishedRuntimeConfig = state.published;
            _publishedRuntimeVersion = state.publishedVersion;
            _runtimeSource = state.sourceLabel;
            if (!_runtimeHasUnsavedChanges && !_savingRuntimeDraft && !_pushingRuntime) {
              _draftRuntimeConfig = state.draft;
              _draftRuntimeVersion = state.draftVersion;
              _syncRuntimeEditors(state.draft);
            }
          });
        });

    _runtimeHistorySubscription = widget.repository
        .watchAiConfigVersionHistory('ai_runtime_config')
        .listen((records) {
          if (!mounted) return;
          setState(() {
            _runtimeHistory = records;
          });
        });

    _assistantRuntimeStateSubscription = widget.repository
        .watchAiAssistantRuntimeConfigState()
        .listen((state) {
          if (!mounted) return;
          setState(() {
            _publishedRuntimeConfig = _publishedRuntimeConfig.copyWith(
              assistantEnabled: state.published.assistantEnabled,
              assistantProvider: state.published.assistantProvider,
              assistantModel: state.published.assistantModel,
              assistantEndpoint: state.published.assistantEndpoint,
              assistantRolePrompt: state.published.assistantRolePrompt,
              assistantTaskPrompt: state.published.assistantTaskPrompt,
              assistantConversationRulesPrompt:
                  state.published.assistantConversationRulesPrompt,
              assistantAbbreviationRulesPrompt:
                  state.published.assistantAbbreviationRulesPrompt,
              assistantAdvancedReasoningPrompt:
                  state.published.assistantAdvancedReasoningPrompt,
              assistantMasterKnowledgePrompt:
                  state.published.assistantMasterKnowledgePrompt,
              assistantActionGuidePrompt:
                  state.published.assistantActionGuidePrompt,
              assistantSystemContractPrompt:
                  state.published.assistantSystemContractPrompt,
              assistantApiKey: state.published.assistantApiKey,
            );
            _publishedAssistantRuntimeVersion = state.publishedVersion;
            if (!_runtimeHasUnsavedChanges &&
                !_savingRuntimeDraft &&
                !_pushingRuntime &&
                !_syncingRuntimeEnabled) {
              _draftRuntimeConfig = _draftRuntimeConfig.copyWith(
                assistantEnabled: state.draft.assistantEnabled,
                assistantProvider: state.draft.assistantProvider,
                assistantModel: state.draft.assistantModel,
                assistantEndpoint: state.draft.assistantEndpoint,
                assistantRolePrompt: state.draft.assistantRolePrompt,
                assistantTaskPrompt: state.draft.assistantTaskPrompt,
                assistantConversationRulesPrompt:
                    state.draft.assistantConversationRulesPrompt,
                assistantAbbreviationRulesPrompt:
                    state.draft.assistantAbbreviationRulesPrompt,
                assistantAdvancedReasoningPrompt:
                    state.draft.assistantAdvancedReasoningPrompt,
                assistantMasterKnowledgePrompt:
                    state.draft.assistantMasterKnowledgePrompt,
                assistantActionGuidePrompt:
                    state.draft.assistantActionGuidePrompt,
                assistantSystemContractPrompt:
                    state.draft.assistantSystemContractPrompt,
                assistantApiKey: state.draft.assistantApiKey,
              );
              _assistantRuntimeEnabled = state.draft.assistantEnabled;
              _assistantProviderController.text = state.draft.assistantProvider
                  .trim()
                  .isNotEmpty
                  ? state.draft.assistantProvider
                  : _providerController.text.trim();
              _assistantModelController.text = state.draft.assistantModel
                  .trim()
                  .isNotEmpty
                  ? state.draft.assistantModel
                  : _modelController.text.trim();
              _assistantEndpointController.text = state.draft.assistantEndpoint
                  .trim()
                  .isNotEmpty
                  ? state.draft.assistantEndpoint
                  : _endpointController.text.trim();
              _assistantApiKeyController.text = state.draft.assistantApiKey
                  .trim()
                  .isNotEmpty
                  ? state.draft.assistantApiKey
                  : _apiKeyController.text.trim();
              _assistantRolePromptController.text = state.draft.assistantRolePrompt;
              _assistantTaskPromptController.text = state.draft.assistantTaskPrompt;
              _assistantConversationRulesPromptController.text =
                  state.draft.assistantConversationRulesPrompt;
              _assistantAbbreviationRulesPromptController.text =
                  state.draft.assistantAbbreviationRulesPrompt;
              _assistantAdvancedReasoningPromptController.text =
                  state.draft.assistantAdvancedReasoningPrompt;
              _assistantMasterKnowledgePromptController.text =
                  state.draft.assistantMasterKnowledgePrompt;
              _assistantActionGuidePromptController.text =
                  state.draft.assistantActionGuidePrompt;
              _assistantSystemContractPromptController.text =
                  state.draft.assistantSystemContractPrompt;
              _draftAssistantRuntimeVersion = state.draftVersion;
            }
          });
        });

    _assistantRuntimeHistorySubscription = widget.repository
        .watchAiConfigVersionHistory('ai_runtime_assistant')
        .listen((records) {
          if (!mounted) return;
          setState(() {
            _assistantRuntimeHistory = records;
          });
        });

    _lexiconHistorySubscription = widget.repository
        .watchAiConfigVersionHistory('ai_lexicon')
        .listen((records) {
          if (!mounted) return;
          setState(() {
            _lexiconHistory = records;
          });
        });
  }

  void _syncRuntimeEditors(AiRuntimeConfig config) {
    _runtimeEnabled = config.enabled;
    _assistantRuntimeEnabled = config.assistantEnabled;
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
    _transactionSystemContractPromptController.text =
        config.transactionSystemContractPrompt;
    _assistantProviderController.text = config.assistantProvider.trim().isNotEmpty
        ? config.assistantProvider
        : config.provider;
    _assistantModelController.text = config.assistantModel.trim().isNotEmpty
        ? config.assistantModel
        : config.model;
    _assistantEndpointController.text = config.assistantEndpoint.trim().isNotEmpty
        ? config.assistantEndpoint
        : config.endpoint;
    _assistantApiKeyController.text = config.assistantApiKey.trim().isNotEmpty
        ? config.assistantApiKey
        : config.apiKey;
    _assistantRolePromptController.text =
        config.assistantRolePrompt.trim().isNotEmpty
        ? config.assistantRolePrompt
        : config.rolePrompt;
    _assistantTaskPromptController.text =
        config.assistantTaskPrompt.trim().isNotEmpty
        ? config.assistantTaskPrompt
        : config.taskPrompt;
    _assistantConversationRulesPromptController.text =
        config.assistantConversationRulesPrompt.trim().isNotEmpty
        ? config.assistantConversationRulesPrompt
        : config.conversationRulesPrompt;
    _assistantAbbreviationRulesPromptController.text =
        config.assistantAbbreviationRulesPrompt.trim().isNotEmpty
        ? config.assistantAbbreviationRulesPrompt
        : config.abbreviationRulesPrompt;
    _assistantAdvancedReasoningPromptController.text =
        config.assistantAdvancedReasoningPrompt;
    _assistantMasterKnowledgePromptController.text =
        config.assistantMasterKnowledgePrompt;
    _assistantActionGuidePromptController.text = config.assistantActionGuidePrompt;
    _assistantSystemContractPromptController.text =
        config.assistantSystemContractPrompt;
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
      transactionSystemContractPrompt:
          _transactionSystemContractPromptController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      assistantEnabled: _assistantRuntimeEnabled,
      assistantProvider: _assistantProviderController.text.trim(),
      assistantModel: _assistantModelController.text.trim(),
      assistantEndpoint: _assistantEndpointController.text.trim(),
      assistantRolePrompt: _assistantRolePromptController.text.trim(),
      assistantTaskPrompt: _assistantTaskPromptController.text.trim(),
      assistantConversationRulesPrompt:
          _assistantConversationRulesPromptController.text.trim(),
      assistantAbbreviationRulesPrompt:
          _assistantAbbreviationRulesPromptController.text.trim(),
      assistantAdvancedReasoningPrompt:
          _assistantAdvancedReasoningPromptController.text.trim(),
      assistantMasterKnowledgePrompt:
          _assistantMasterKnowledgePromptController.text.trim(),
      assistantActionGuidePrompt:
          _assistantActionGuidePromptController.text.trim(),
      assistantSystemContractPrompt:
          _assistantSystemContractPromptController.text.trim(),
      assistantApiKey: _assistantApiKeyController.text.trim(),
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
      final nextVersion =
          (_publishedVersion > _draftVersion ? _publishedVersion : _draftVersion) +
          1;
      await widget.repository.saveAiLexiconRaw(
        raw: raw,
        actor: widget.profile,
        nextVersion: nextVersion,
      );
      if (!mounted) return;
      setState(() {
        _draftRaw = raw;
        _draftVersion = nextVersion;
        _publishedVersion = nextVersion;
        _editingParse = false;
        _message = 'Đã lưu cấu hình AI parse.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingDraft = false;
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
      final nextVersion =
          (_publishedRuntimeVersion > _draftRuntimeVersion
              ? _publishedRuntimeVersion
              : _draftRuntimeVersion) +
          1;
      await widget.repository.saveAiRuntimeConfigRaw(
        config: next,
        actor: widget.profile,
        nextVersion: nextVersion,
      );
      if (!mounted) return;
      setState(() {
        _draftRuntimeConfig = next;
        _publishedRuntimeConfig = next;
        _draftRuntimeVersion = nextVersion;
        _publishedRuntimeVersion = nextVersion;
        _editingTransactionRuntime = false;
        _runtimeMessage = 'Đã lưu cấu hình AI giao dịch.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingRuntimeDraft = false;
        });
      }
    }
  }

  Future<void> _setRuntimeEnabledLive(bool value) async {
    if (_syncingRuntimeEnabled) return;

    final nextDraft = _buildDraftRuntimeConfig().copyWith(enabled: value);
    final nextPublished = _publishedRuntimeConfig.copyWith(enabled: value);

    setState(() {
      _syncingRuntimeEnabled = true;
      _runtimeEnabled = value;
      _runtimeMessage = null;
    });

    try {
      await widget.repository.saveAiRuntimeConfigDraft(
        config: nextDraft,
        actor: widget.profile,
        nextVersion: _draftRuntimeVersion + 1,
      );
      await widget.repository.saveAiRuntimeConfigRaw(
        config: nextPublished,
        actor: widget.profile,
        nextVersion: _publishedRuntimeVersion + 1,
      );

      if (!mounted) return;
      setState(() {
        _draftRuntimeConfig = nextDraft;
        _publishedRuntimeConfig = nextPublished;
        _draftRuntimeVersion += 1;
        _publishedRuntimeVersion += 1;
        _runtimeSource = 'Runtime Firestore';
        _runtimeMessage = value
            ? 'Đã mở AI thật cho bản chạy ngay lập tức.'
            : 'Đã khóa AI thật trên bản chạy ngay lập tức.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _runtimeEnabled = _draftRuntimeConfig.enabled;
        _runtimeMessage =
            'Không cập nhật được trạng thái AI thật. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _syncingRuntimeEnabled = false;
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
      final result = await _aiService.processTransactionInput(input);
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
      final result = await _aiService.processTransactionInput(
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

  Future<void> _runPublishedRuntimeProbe() async {
    final input = _runtimePreviewInputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _publishedRuntimeProbeMessage =
            'Nhập một câu để kiểm tra runtime đang publish.';
      });
      return;
    }

    setState(() {
      _publishedRuntimeProbeLoading = true;
      _publishedRuntimeProbeMessage = null;
    });
    try {
      final result = await _aiService.processTransactionInput(
        input,
        runtimeOverride: _publishedRuntimeConfig,
      );
      if (!mounted) return;
      setState(() {
        _publishedRuntimeProbeResult = result;
        _publishedRuntimeProbeMessage =
            'Đã kiểm tra bằng runtime đang publish. Nếu nguồn trả về là remote_ai thì key live đang chạy được.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _publishedRuntimeProbeLoading = false;
        });
      }
    }
  }

  Future<void> _setAssistantEnabledLive(bool value) async {
    if (_syncingRuntimeEnabled) return;

    final nextDraft = _buildDraftRuntimeConfig().copyWith(
      assistantEnabled: value,
    );
    final nextPublished = _publishedRuntimeConfig.copyWith(
      assistantEnabled: value,
    );

    setState(() {
      _syncingRuntimeEnabled = true;
      _assistantRuntimeEnabled = value;
      _assistantRuntimeMessage = null;
    });

    try {
      await widget.repository.saveAiAssistantRuntimeConfigDraft(
        config: nextDraft,
        actor: widget.profile,
        nextVersion: _draftAssistantRuntimeVersion + 1,
      );
      await widget.repository.saveAiAssistantRuntimeConfigRaw(
        config: nextPublished,
        actor: widget.profile,
        nextVersion: _publishedAssistantRuntimeVersion + 1,
      );

      if (!mounted) return;
      setState(() {
        _draftRuntimeConfig = nextDraft;
        _publishedRuntimeConfig = nextPublished;
        _draftAssistantRuntimeVersion += 1;
        _publishedAssistantRuntimeVersion += 1;
        _assistantRuntimeMessage = value
            ? 'Đã mở AI hỗ trợ cho bản chạy ngay lập tức.'
            : 'Đã tắt AI hỗ trợ trên bản chạy ngay lập tức.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _assistantRuntimeEnabled = _draftRuntimeConfig.assistantEnabled;
        _assistantRuntimeMessage =
            'Không cập nhật được trạng thái AI hỗ trợ. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _syncingRuntimeEnabled = false;
        });
      }
    }
  }

  Future<void> _saveAssistantRuntimeDraft() async {
    setState(() {
      _savingRuntimeDraft = true;
      _assistantRuntimeMessage = null;
    });
    try {
      final next = _buildDraftRuntimeConfig();
      final nextVersion =
          (_publishedAssistantRuntimeVersion > _draftAssistantRuntimeVersion
              ? _publishedAssistantRuntimeVersion
              : _draftAssistantRuntimeVersion) +
          1;
      await widget.repository.saveAiAssistantRuntimeConfigRaw(
        config: next,
        actor: widget.profile,
        nextVersion: nextVersion,
      );
      if (!mounted) return;
      setState(() {
        _draftRuntimeConfig = next;
        _publishedRuntimeConfig = next;
        _draftAssistantRuntimeVersion = nextVersion;
        _publishedAssistantRuntimeVersion = nextVersion;
        _editingAssistantRuntime = false;
        _assistantRuntimeMessage = 'Đã lưu cấu hình AI hỗ trợ.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingRuntimeDraft = false;
        });
      }
    }
  }
  Future<void> _runAssistantPreview() async {
    final input = _assistantPreviewInputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _assistantPreviewMessage = 'Nhập một câu hỏi để xem trước AI hỗ trợ.';
      });
      return;
    }
    setState(() {
      _assistantPreviewLoading = true;
      _assistantPreviewMessage = null;
    });
    try {
      final result = await _aiService.processAssistantInput(
        input,
        runtimeOverride: _buildDraftRuntimeConfig(),
      );
      if (!mounted) return;
      setState(() {
        _assistantPreviewResult = result;
        _assistantPreviewMessage =
            'Đã xem trước bằng bản nháp AI hỗ trợ. Bản chạy hiện tại không bị thay đổi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _assistantPreviewLoading = false;
        });
      }
    }
  }

  Future<void> _runPublishedAssistantProbe() async {
    final input = _assistantPreviewInputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _assistantPublishedProbeMessage =
            'Nhập một câu hỏi để kiểm tra AI hỗ trợ đang publish.';
      });
      return;
    }
    setState(() {
      _assistantPublishedProbeLoading = true;
      _assistantPublishedProbeMessage = null;
    });
    try {
      final result = await _aiService.processAssistantInput(
        input,
        runtimeOverride: _publishedRuntimeConfig,
      );
      if (!mounted) return;
      setState(() {
        _assistantPublishedProbeResult = result;
        _assistantPublishedProbeMessage =
            'Đã kiểm tra bằng cấu hình AI hỗ trợ đang publish.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _assistantPublishedProbeLoading = false;
        });
      }
    }
  }

  String _runtimeHealthLabel(AiRuntimeConfig config) {
    if (!config.enabled) return 'AI thật đang tắt';
    if (!config.hasApiKey) return 'Thiếu API key';
    if (!config.canUseRemoteAi) return 'Thiếu cấu hình runtime';
    return 'Sẵn sàng gọi AI thật';
  }

  String _assistantRuntimeHealthLabel(AiRuntimeConfig config) {
    if (!config.assistantEnabled) return 'AI hỗ trợ đang tắt';
    if (config.effectiveAssistantApiKey.trim().isEmpty) return 'Thiếu API key';
    if (!config.canUseAssistantRemoteAi) return 'Thiếu cấu hình AI hỗ trợ';
    return 'Sẵn sàng gọi AI hỗ trợ';
  }

  Future<void> _rollbackRuntimeVersion(AiConfigVersionRecord version) async {
    setState(() {
      _rollingBackRuntime = true;
      _runtimeMessage = null;
      _assistantRuntimeMessage = null;
    });
    try {
      await widget.repository.rollbackAiRuntimeConfigVersion(
        version: version,
        actor: widget.profile,
        nextVersion: _publishedRuntimeVersion + 1,
      );
      if (!mounted) return;
      setState(() {
        _runtimeMessage = 'Đã khôi phục runtime về bản v${version.version}.';
        _assistantRuntimeMessage =
            'Đã khôi phục AI hỗ trợ về bản runtime v${version.version}.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _rollingBackRuntime = false;
        });
      }
    }
  }

  Future<void> _rollbackAssistantRuntimeVersion(
    AiConfigVersionRecord version,
  ) async {
    setState(() {
      _rollingBackRuntime = true;
      _assistantRuntimeMessage = null;
    });
    try {
      await widget.repository.rollbackAiAssistantRuntimeConfigVersion(
        version: version,
        actor: widget.profile,
        nextVersion: _publishedAssistantRuntimeVersion + 1,
      );
      if (!mounted) return;
      setState(() {
        _assistantRuntimeMessage =
            'Đã khôi phục AI hỗ trợ về bản v${version.version}.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _rollingBackRuntime = false;
        });
      }
    }
  }

  Future<void> _rollbackLexiconVersion(AiConfigVersionRecord version) async {
    setState(() {
      _rollingBackLexicon = true;
      _message = null;
    });
    try {
      await widget.repository.rollbackAiLexiconVersion(
        version: version,
        actor: widget.profile,
        nextVersion: _publishedVersion + 1,
      );
      if (!mounted) return;
      setState(() {
        _message = 'Đã khôi phục local parse về bản v${version.version}.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _rollingBackLexicon = false;
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
    final runtimeDraft = _buildDraftRuntimeConfig();
    final groups = _buildSummaryGroups(
      lexicon: lexicon,
      runtimeDraft: runtimeDraft,
      publishedRuntime: _publishedRuntimeConfig,
    );

    return ListView(
      children: [
        Wrap(
          runSpacing: 14,
          spacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
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
        AdminPanel(
          title: 'Điều hướng cấu hình AI',
          isExpanded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildConfigTabButton(
                    label: 'AI thêm giao dịch',
                    icon: Icons.receipt_long_rounded,
                    index: 0,
                  ),
                  _buildConfigTabButton(
                    label: 'AI hỗ trợ',
                    icon: Icons.support_agent_rounded,
                    index: 1,
                  ),
                  _buildConfigTabButton(
                    label: 'AI parse',
                    icon: Icons.rule_folder_outlined,
                    index: 2,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_selectedTabIndex == 0) ...[
                _buildRuntimeConfigPanel(runtimeDraft),
                const SizedBox(height: 18),
                _buildCompiledPromptPanel(
                  title: 'Prompt tổng hợp cuối cùng',
                  subtitle:
                      'Bản prompt runtime cuối cùng đang được ghép từ 6 tầng draft hiện tại của AI thêm giao dịch.',
                  prompt: runtimeDraft.buildSystemPrompt(
                    categories: const <Map<String, dynamic>>[],
                    now: DateTime.now(),
                  ),
                  accent: const Color(0xFF155EEF),
                ),
                const SizedBox(height: 18),
                _buildRuntimePreviewPanel(),
              ] else if (_selectedTabIndex == 1) ...[
                _buildAssistantRuntimePanel(runtimeDraft),
                const SizedBox(height: 18),
                _buildCompiledPromptPanel(
                  title: 'Prompt tổng hợp cuối cùng',
                  subtitle:
                      'Bản prompt runtime cuối cùng đang được ghép từ 8 tầng draft hiện tại của AI hỗ trợ.',
                  prompt: runtimeDraft.buildAssistantSystemPrompt(
                    contextSummary:
                        '- Đây là bản xem tổng hợp từ admin, chưa gắn với một câu hỏi cụ thể của user.\n- Khi publish, app sẽ dùng prompt này cùng context runtime thật.',
                    now: DateTime.now(),
                  ),
                  accent: const Color(0xFF087C6C),
                ),
                const SizedBox(height: 18),
                _buildAssistantPreviewPanel(),
              ] else ...[
                _buildLexiconPanel(),
                const SizedBox(height: 18),
                _buildCompiledPromptPanel(
                  title: 'Khung tổng hợp Local Parse',
                  subtitle:
                      'Bản từ điển Local Parse đang được ghép từ toàn bộ nhóm dữ liệu hiện tại của bản nháp.',
                  prompt: raw,
                  accent: const Color(0xFF7A5AF8),
                ),
                const SizedBox(height: 18),
                _buildLocalPreviewPanel(),
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
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildConfigTabButton({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final selected = _selectedTabIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE8F0FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? const Color(0xFF1D4ED8)
              : const Color(0xFFD0D5DD),
          width: selected ? 1.8 : 1,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x221D4ED8),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF475467),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF475467),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuntimeConfigPanel(AiRuntimeConfig runtimeDraft) {
    return AdminPanel(
      title: 'AI thêm giao dịch',
      isExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CountPill(label: _publishedRuntimeConfig.enabled ? 'Đang bật' : 'Đang tắt'),
              _CountPill(label: _runtimeHealthLabel(_publishedRuntimeConfig)),
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
                  onChanged: !_editingTransactionRuntime || _syncingRuntimeEnabled
                      ? null
                      : (value) => _setRuntimeEnabledLive(value),
                  title: const Text(
                    'Bat che do AI that',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    _syncingRuntimeEnabled
                        ? 'Đang cập nhật bản chạy cho user...'
                        : 'Đây là khóa nóng. Khi đổi công tắc này, user sẽ bị bật hoặc khóa AI ngay trên app.',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _providerController,
                        enabled: _editingTransactionRuntime,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Nhà cung cấp',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _modelController,
                        enabled: _editingTransactionRuntime,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Mô hình'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _endpointController,
                  enabled: _editingTransactionRuntime,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Điểm cuối API'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _fallbackPolicy,
                        onChanged: !_editingTransactionRuntime
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _fallbackPolicy = value;
                                });
                              },
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _imageStrategy,
                        onChanged: !_editingTransactionRuntime
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _imageStrategy = value;
                                });
                              },
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  enabled: _editingTransactionRuntime,
                  onChanged: (_) => setState(() {}),
                  obscureText: !_showApiKey,
                  decoration: InputDecoration(
                    labelText: 'Khóa API Groq',
                    helperText: runtimeDraft.hasApiKey
                        ? 'Key hien tai: ${runtimeDraft.maskedApiKey}. Sau khi publish, dung nut kiem tra ben duoi de xac nhan app dang goi AI that.'
                        : 'Chua co key runtime',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: !_editingTransactionRuntime
                              ? null
                              : () {
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
                          onPressed: !_editingTransactionRuntime
                              ? null
                              : () {
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
            enabled: _editingTransactionRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 2: Nhiệm vụ',
            subtitle: 'Nhiệm vụ và cách phân loại ý định.',
            controller: _taskPromptController,
            enabled: _editingTransactionRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 3: Quy tắc tạo thẻ',
            subtitle: 'Khi nào được tạo thẻ, khi nào phải hỏi lại.',
            controller: _cardRulesPromptController,
            enabled: _editingTransactionRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 4: Quy tắc hội thoại',
            subtitle: 'Quy tắc trả lời tự nhiên cho ngữ cảnh rộng.',
            controller: _conversationRulesPromptController,
            enabled: _editingTransactionRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 5: Viết tắt / Tiếng lóng / Địa phương',
            subtitle:
                'Chuan hoa viet tat, slang, cach noi doi thuong, va bien the dia phuong truoc khi suy luan nghiep vu.',
            controller: _abbreviationRulesPromptController,
            enabled: _editingTransactionRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 6: Contract và rule hệ thống',
            subtitle:
                'Định nghĩa hợp đồng đầu ra JSON và các quy tắc hệ thống bắt buộc của AI giao dịch.',
            controller: _transactionSystemContractPromptController,
            enabled: _editingTransactionRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _editingTransactionRuntime = !_editingTransactionRuntime;
                  });
                },
                icon: Icon(
                  _editingTransactionRuntime
                      ? Icons.lock_open_rounded
                      : Icons.edit_rounded,
                ),
                label: Text(
                  _editingTransactionRuntime ? 'Đang chỉnh sửa' : 'Chỉnh sửa',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _syncRuntimeEditors(_publishedRuntimeConfig);
                    _runtimeMessage = 'Đã khôi phục bản nháp theo bản chính thức.';
                    _editingTransactionRuntime = false;
                  });
                },
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Khôi phục'),
              ),
              FilledButton.tonalIcon(
                onPressed: !_editingTransactionRuntime || _savingRuntimeDraft
                    ? null
                    : _saveRuntimeDraft,
                icon: _savingRuntimeDraft
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantRuntimePanel(AiRuntimeConfig runtimeDraft) {
    return AdminPanel(
      title: 'AI hỗ trợ',
      isExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CountPill(label: _assistantRuntimeEnabled ? 'Đang bật' : 'Đang tắt'),
              _CountPill(
                label: runtimeDraft.effectiveAssistantApiKey.trim().isNotEmpty
                    ? 'API key: ${runtimeDraft.assistantApiKey.trim().isNotEmpty ? _maskKey(runtimeDraft.assistantApiKey) : runtimeDraft.maskedApiKey}'
                    : 'API key: chưa có',
              ),
            ],
          ),
          if (_assistantRuntimeMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDDEEE6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _assistantRuntimeMessage!,
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
                  value: _assistantRuntimeEnabled,
                  onChanged: !_editingAssistantRuntime || _syncingRuntimeEnabled
                      ? null
                      : (value) => _setAssistantEnabledLive(value),
                  title: const Text(
                    'Bật AI hỗ trợ cho app',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Công tắc này tác động trực tiếp lên bản chạy. Khi tắt, tab AI hỗ trợ sẽ bị ẩn trong app.',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _assistantProviderController,
                        enabled: _editingAssistantRuntime,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Nhà cung cấp',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _assistantModelController,
                        enabled: _editingAssistantRuntime,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Mô hình'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _assistantEndpointController,
                  enabled: _editingAssistantRuntime,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Điểm cuối API'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _assistantApiKeyController,
                  enabled: _editingAssistantRuntime,
                  onChanged: (_) => setState(() {}),
                  obscureText: !_showAssistantApiKey,
                  decoration: InputDecoration(
                    labelText: 'Khóa API AI hỗ trợ',
                    helperText: runtimeDraft.effectiveAssistantApiKey.trim().isNotEmpty
                        ? 'Key hiện tại: ${runtimeDraft.assistantApiKey.trim().isNotEmpty ? _maskKey(runtimeDraft.assistantApiKey) : runtimeDraft.maskedApiKey}'
                        : 'Chưa có key AI hỗ trợ',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: !_editingAssistantRuntime
                              ? null
                              : () {
                                  setState(() {
                                    _showAssistantApiKey = !_showAssistantApiKey;
                                  });
                                },
                          icon: Icon(
                            _showAssistantApiKey
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        IconButton(
                          onPressed: !_editingAssistantRuntime
                              ? null
                              : () {
                                  setState(() {
                                    _assistantApiKeyController.clear();
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
            title: 'Tầng 1: Vai trò AI hỗ trợ',
            subtitle: 'Giọng điệu và phạm vi hỗ trợ cho người dùng.',
            controller: _assistantRolePromptController,
            enabled: _editingAssistantRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 2: Nhiệm vụ AI hỗ trợ',
            subtitle: 'Các loại câu hỏi AI hỗ trợ được phép trả lời.',
            controller: _assistantTaskPromptController,
            enabled: _editingAssistantRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 3: Quy tắc hội thoại AI hỗ trợ',
            subtitle: 'Giới hạn trả lời, hành động an toàn và cách gợi ý điều hướng.',
            controller: _assistantConversationRulesPromptController,
            enabled: _editingAssistantRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 4: Tiếng lóng / viết tắt / sai chính tả / không dấu',
            subtitle: 'Giúp AI hiểu cách nói đời thường trước khi tạo câu trả lời.',
            controller: _assistantAbbreviationRulesPromptController,
            enabled: _editingAssistantRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 5: Xử lý khôn khéo tình huống nghiệp vụ',
            subtitle: 'Dạy AI trả lời thông minh, mềm và rõ ràng khi câu hỏi quá rộng hoặc quá nghiệp vụ.',
            controller: _assistantAdvancedReasoningPromptController,
            enabled: _editingAssistantRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 6: Master prompt toàn app',
            subtitle:
                'Bản đồ sản phẩm và năng lực bao quát toàn app của AI hỗ trợ.',
            controller: _assistantMasterKnowledgePromptController,
            enabled: _editingAssistantRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 7: Action guide',
            subtitle:
                'Danh sách action hợp lệ để AI gợi ý điều hướng đúng màn hình.',
            controller: _assistantActionGuidePromptController,
            enabled: _editingAssistantRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PromptEditorCard(
            title: 'Tầng 8: Contract và rule hệ thống',
            subtitle:
                'Hợp đồng đầu ra JSON và các quy tắc bắt buộc riêng của AI hỗ trợ.',
            controller: _assistantSystemContractPromptController,
            enabled: _editingAssistantRuntime,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _editingAssistantRuntime = !_editingAssistantRuntime;
                  });
                },
                icon: Icon(
                  _editingAssistantRuntime
                      ? Icons.lock_open_rounded
                      : Icons.edit_rounded,
                ),
                label: Text(
                  _editingAssistantRuntime ? 'Đang chỉnh sửa' : 'Chỉnh sửa',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _syncRuntimeEditors(_publishedRuntimeConfig);
                    _assistantRuntimeMessage =
                        'Đã khôi phục bản nháp theo bản chính thức.';
                    _editingAssistantRuntime = false;
                  });
                },
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Khôi phục'),
              ),
              FilledButton.tonalIcon(
                onPressed: !_editingAssistantRuntime || _savingRuntimeDraft
                    ? null
                    : _saveAssistantRuntimeDraft,
                icon: _savingRuntimeDraft
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu'),
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
                onPressed: _editingParse ? _importFile : null,
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Nhập tệp'),
              ),
              FilledButton.tonalIcon(
                onPressed: _editingParse ? () => _showSectionDialog() : null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm nhóm'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _editingParse = !_editingParse;
                  });
                },
                icon: Icon(
                  _editingParse ? Icons.lock_open_rounded : Icons.edit_rounded,
                ),
                label: Text(_editingParse ? 'Đang chỉnh sửa' : 'Chỉnh sửa'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _sections = _parseSections(_draftRaw);
                    _message = 'Đã khôi phục về cấu hình đang lưu.';
                    _editingParse = false;
                  });
                },
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Khôi phục'),
              ),
              FilledButton.tonalIcon(
                onPressed: !_editingParse || _savingDraft ? null : _saveDraft,
                icon: _savingDraft
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu'),
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
              FilledButton.tonalIcon(
                onPressed: _publishedRuntimeProbeLoading
                    ? null
                    : _runPublishedRuntimeProbe,
                icon: _publishedRuntimeProbeLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering_rounded),
                label: const Text('Kiểm tra bản chạy'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _runtimePreviewResult = null;
                    _runtimePreviewMessage = null;
                    _publishedRuntimeProbeResult = null;
                    _publishedRuntimeProbeMessage = null;
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
          if (_publishedRuntimeProbeMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _publishedRuntimeProbeMessage!,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _PreviewResult(result: _runtimePreviewResult),
          if (_publishedRuntimeProbeResult != null) ...[
            const SizedBox(height: 14),
            const Text(
              'Kết quả runtime đang publish',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _PreviewResult(result: _publishedRuntimeProbeResult),
          ],
        ],
      ),
    );
  }

  Widget _buildAssistantPreviewPanel() {
    return AdminPanel(
      title: 'Xem trước AI hỗ trợ',
      isExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bản xem trước này dùng bản nháp AI hỗ trợ. Bạn có thể kiểm tra cách trả lời, gợi ý điều hướng, và dữ liệu ngân sách/tiết kiệm trước khi publish.',
            style: TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _assistantPreviewInputController,
            decoration: const InputDecoration(
              labelText: 'Nhập câu hỏi cho AI hỗ trợ',
              hintText: 'Ví dụ: tháng này mình chi bao nhiêu rồi?',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _assistantPreviewLoading ? null : _runAssistantPreview,
                icon: _assistantPreviewLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.support_agent_rounded),
                label: const Text('Xem trước AI hỗ trợ'),
              ),
              FilledButton.tonalIcon(
                onPressed: _assistantPublishedProbeLoading
                    ? null
                    : _runPublishedAssistantProbe,
                icon: _assistantPublishedProbeLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering_rounded),
                label: const Text('Kiểm tra bản chạy'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _assistantPreviewResult = null;
                    _assistantPreviewMessage = null;
                    _assistantPublishedProbeResult = null;
                    _assistantPublishedProbeMessage = null;
                  });
                },
                child: const Text('Xóa xem trước'),
              ),
            ],
          ),
          if (_assistantPreviewMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _assistantPreviewMessage!,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_assistantPublishedProbeMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _assistantPublishedProbeMessage!,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _PreviewResult(result: _assistantPreviewResult),
          if (_assistantPublishedProbeResult != null) ...[
            const SizedBox(height: 14),
            const Text(
              'Kết quả AI hỗ trợ đang publish',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _PreviewResult(result: _assistantPublishedProbeResult),
          ],
        ],
      ),
    );
  }

  Widget _buildVersionHistoryPanel({
    required String title,
    required List<AiConfigVersionRecord> records,
    required bool rollingBack,
    required Future<void> Function(AiConfigVersionRecord version) onRestore,
    required String emptyLabel,
  }) {
    final visibleRecords = records.where((record) {
      final isCurrent =
          (record.configKey == 'ai_runtime_config' &&
              record.version == _publishedRuntimeVersion) ||
          (record.configKey == 'ai_runtime_assistant' &&
              record.version == _publishedAssistantRuntimeVersion) ||
          (record.configKey == 'ai_lexicon' &&
              record.version == _publishedVersion);
      return !isCurrent;
    }).take(3).toList(growable: false);

    return AdminPanel(
      title: title,
      isExpanded: false,
      child: Column(
        children: [
          if (visibleRecords.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(emptyLabel),
            )
          else
            ...visibleRecords.map((record) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phiên bản v${record.version}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Cập nhật bởi ${record.adminEmail.isNotEmpty ? record.adminEmail : 'không rõ'}'
                              '${record.createdAt != null ? ' · ${_formatTimestamp(record.createdAt!)}' : ''}',
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: rollingBack ? null : () => onRestore(record),
                        icon: rollingBack
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.history_toggle_off_rounded),
                        label: const Text('Khôi phục'),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _maskKey(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= 8) return '••••••••';
    return '${trimmed.substring(0, 4)}••••${trimmed.substring(trimmed.length - 4)}';
  }

  String _formatTimestamp(Timestamp timestamp) {
    return MaterialLocalizations.of(
      context,
    ).formatFullDate(timestamp.toDate()) +
        ' ' +
        MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(timestamp.toDate()),
        );
  }

  List<_SummaryGroup> _buildSummaryGroups({
    required TransactionPhraseLexicon lexicon,
    required AiRuntimeConfig runtimeDraft,
    required AiRuntimeConfig publishedRuntime,
  }) {
    final activeKeys = <bool>[
      runtimeDraft.hasApiKey,
      runtimeDraft.effectiveAssistantApiKey.trim().isNotEmpty,
    ].where((value) => value).length;
    final liveAis = <bool>[
      publishedRuntime.enabled,
      publishedRuntime.assistantEnabled,
    ].where((value) => value).length;

    return <_SummaryGroup>[
      _SummaryGroup(
        label: 'AI giao dịch',
        value: '6',
        badge: publishedRuntime.enabled ? 'dang bat' : 'dang tat',
        note:
            'Key ${runtimeDraft.hasApiKey ? 'san sang' : 'chua co'} · ${publishedRuntime.canUseRemoteAi ? 'AI that san sang' : 'can bo sung cau hinh'}',
        tint: const Color(0xFF155EEF),
        icon: Icons.receipt_long_rounded,
      ),
      _SummaryGroup(
        label: 'AI hỗ trợ',
        value: '8',
        badge: publishedRuntime.assistantEnabled ? 'dang bat' : 'dang tat',
        note:
            'Key ${runtimeDraft.effectiveAssistantApiKey.trim().isNotEmpty ? 'san sang' : 'chua co'} · ${publishedRuntime.canUseAssistantRemoteAi ? 'sẵn sàng hỗ trợ' : 'can bo sung cau hinh'}',
        tint: const Color(0xFF087C6C),
        icon: Icons.support_agent_rounded,
      ),
      _SummaryGroup(
        label: 'AI parse',
        value: '${_sections.length}',
        badge: _editingParse ? 'dang sua' : 'dang xem',
        note:
            '${lexicon.categoryPhrases.length} nhom danh muc · ${_hasUnsavedChanges ? 'co thay doi chua luu' : 'ban nhap da dong bo'}',
        tint: const Color(0xFF7A5AF8),
        icon: Icons.rule_folder_outlined,
      ),
      _SummaryGroup(
        label: 'API key đang có',
        value: '$activeKeys/2',
        badge: activeKeys == 2 ? 'day du' : 'can bo sung',
        note:
            'Giao dịch ${runtimeDraft.hasApiKey ? 'co' : 'thieu'} · Hỗ trợ ${runtimeDraft.effectiveAssistantApiKey.trim().isNotEmpty ? 'co' : 'thieu'}',
        tint: const Color(0xFF344054),
        icon: Icons.key_rounded,
      ),
      _SummaryGroup(
        label: 'AI đang hoạt động',
        value: '$liveAis/2',
        badge: liveAis == 2 ? 'online' : 'mot phan',
        note:
            'Giao dịch ${publishedRuntime.enabled ? 'bat' : 'tat'} · Hỗ trợ ${publishedRuntime.assistantEnabled ? 'bat' : 'tat'}',
        tint: const Color(0xFFDC6803),
        icon: Icons.toggle_on_rounded,
      ),
      _SummaryGroup(
        label: 'Bao phủ cấu hình',
        value: '14',
        badge: 'tong so tang',
        note:
            '6 tầng AI giao dịch · 8 tầng AI hỗ trợ · ${lexicon.prioritySections.length} rule ưu tiên parse',
        tint: const Color(0xFF6941C6),
        icon: Icons.layers_rounded,
      ),
    ];
  }

  Widget _buildCompiledPromptPanel({
    required String title,
    required String subtitle,
    required String prompt,
    required Color accent,
  }) {
    return AdminPanel(
      title: title,
      isExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
                ),
                title: const Text(
                  'Xem nội dung tổng hợp',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  prompt.trim().isEmpty
                      ? 'Chưa có nội dung.'
                      : '${prompt.trim().length} ký tự',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                    ),
                    child: SelectableText(
                      prompt.trim().isEmpty ? 'Chưa có nội dung.' : prompt,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptEditorCard extends StatelessWidget {
  const _PromptEditorCard({
    required this.title,
    required this.subtitle,
    required this.controller,
    this.enabled = true,
    this.onChanged,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF155EEF).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF155EEF),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            TextField(
              controller: controller,
              enabled: enabled,
              onChanged: (_) => onChanged?.call(),
              minLines: 5,
              maxLines: 9,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7A5AF8).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF7A5AF8),
            ),
          ),
          title: Text(
            section.key,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${section.values.length} từ trong nhóm này',
              style: const TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing: _CountPill(label: '${section.values.length} từ'),
          children: [
            Row(
              children: [
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
        gradient: LinearGradient(
          colors: [
            Colors.white,
            group.tint.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: group.tint.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: group.tint.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: group.tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(group.icon, color: group.tint, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: group.tint.withValues(alpha: 0.18)),
                ),
                child: Text(
                  group.badge,
                  style: TextStyle(
                    color: group.tint,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            group.value,
            style: TextStyle(
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              color: group.tint,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            group.label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            group.note,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
              height: 1.4,
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
    required this.badge,
    required this.note,
    required this.tint,
    required this.icon,
  });

  final String label;
  final String value;
  final String badge;
  final String note;
  final Color tint;
  final IconData icon;
}

class _LexiconSection {
  const _LexiconSection({required this.key, required this.values});

  final String key;
  final List<String> values;
}
