import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
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

  List<_LexiconSection> _sections = <_LexiconSection>[];
  String _publishedRaw = '';
  String _draftRaw = '';
  int _publishedVersion = 1;
  int _draftVersion = 1;
  String _source = 'data.text';
  bool _loading = true;
  bool _savingDraft = false;
  bool _pushing = false;
  bool _previewLoading = false;
  String? _message;
  String? _previewMessage;
  Map<String, dynamic>? _previewResult;

  bool get _hasUnsavedChanges => _buildRaw().trim() != _draftRaw.trim();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _previewInputController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = await widget.repository.loadAiLexiconState();
    final editableRaw = state.draftRaw.trim().isNotEmpty ? state.draftRaw : state.raw;
    if (!mounted) return;
    setState(() {
      _publishedRaw = state.raw;
      _draftRaw = editableRaw;
      _publishedVersion = state.version;
      _draftVersion = state.draftRaw.trim().isNotEmpty
          ? state.draftVersion
          : state.version;
      _source = state.sourceLabel;
      _sections = _parseSections(editableRaw);
      _loading = false;
      _message = null;
      _previewMessage = null;
      _previewResult = null;
    });
  }

  Future<void> _importFile() async {
    final controller = TextEditingController();
    String? importedRaw;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhap noi dung file AI'),
        content: SizedBox(
          width: 720,
          child: TextField(
            controller: controller,
            minLines: 16,
            maxLines: 22,
            decoration: const InputDecoration(
              hintText: 'Dan noi dung data.text hoac file txt vao day...',
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                return;
              }
              importedRaw = value;
              Navigator.of(context).pop();
            },
            child: const Text('Nhap'),
          ),
        ],
      ),
    );
    final raw = importedRaw;
    if (raw == null || raw.isEmpty) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _sections = _parseSections(raw);
      _message = 'Da nap noi dung AI va tach cac nhom du lieu.';
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
        _message = 'Da luu nhap cau hinh AI.';
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
        _publishedRaw = raw;
        _draftVersion += 1;
        _publishedVersion += 1;
        _source = 'Firestore config';
        _message = 'Da day cau hinh AI len ban dang hoat dong.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _pushing = false;
        });
      }
    }
  }

  Future<void> _runPreview() async {
    final input = _previewInputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _previewMessage = 'Nhap mot cau giao dich de preview.';
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
        _previewMessage = 'Da phan tich voi ban nhap hien tai.';
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
              title: Text(section == null ? 'Them nhom du lieu' : 'Sua nhom du lieu'),
              content: SizedBox(
                width: 620,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: 'Ma nhom',
                        hintText: 'Vi du: TYPE_CREDIT, AN_UONG...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: valuesController,
                      minLines: 8,
                      maxLines: 14,
                      decoration: const InputDecoration(
                        labelText: 'Danh sach tu khoa',
                        hintText: 'Cach nhau boi dau phay hoac xuong dong',
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
                  child: const Text('Huy'),
                ),
                FilledButton(
                  onPressed: () {
                    final key = keyController.text.trim().toUpperCase();
                    final values = _parseValues(valuesController.text);
                    if (key.isEmpty) {
                      setDialogState(() {
                        errorText = 'Ma nhom khong duoc de trong.';
                      });
                      return;
                    }
                    if (values.isEmpty) {
                      setDialogState(() {
                        errorText = 'Can it nhat 1 tu khoa.';
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
                  child: const Text('Luu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _buildRaw() {
    return _sections
        .where((section) => section.key.trim().isNotEmpty && section.values.isNotEmpty)
        .map((section) => '${section.key}::${section.values.join(',')}')
        .join('\n');
  }

  List<_LexiconSection> _parseSections(String raw) {
    final sections = <_LexiconSection>[];
    for (final rawLine in raw.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }
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

  Future<void> _showSystemFileDialog(String raw) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File he thong AI'),
        content: SizedBox(
          width: 760,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Day la file he thong dai dien cho cau hinh goc. File nay chi de xem doi chieu, khong sua truc tiep va khong duoc xoa de tranh mat chuc nang AI.',
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
            child: const Text('Dong'),
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

    return ListView(
      children: [
        Wrap(
          runSpacing: 14,
          spacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 520,
              child: Text(
                'Cau hinh AI dang duoc tach thanh tung nhom de sua nhanh, co luu nhap va day len ban hoat dong rieng.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            AdminRolePill(label: 'ban chay v$_publishedVersion'),
            AdminRolePill(label: 'ban nhap v$_draftVersion'),
            AdminRolePill(label: _source),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tai lai'),
            ),
            OutlinedButton.icon(
              onPressed: _importFile,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Nhap file'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _sections = _parseSections(_publishedRaw);
                  _message = 'Da khoi phuc ban nhap theo ban dang hoat dong.';
                });
              },
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Khoi phuc ban chay'),
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
              label: const Text('Luu nhap'),
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
              label: const Text('Day ban chay'),
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
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: groups
              .map(
                (group) => SizedBox(
                  width: 240,
                  child: _SummaryCard(group: group),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        AdminPanel(
          title: 'Cac nhom du lieu',
          isExpanded: false,
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 12,
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                  FilledButton.tonalIcon(
                    onPressed: () => _showSectionDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Them nhom'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_sections.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text('Chua co nhom du lieu nao.'),
                  ),
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
                      onEdit: () => _showSectionDialog(
                        section: section,
                        index: index,
                      ),
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
        ),
        const SizedBox(height: 18),
        AdminPanel(
          title: 'Xem truoc giong ben user',
          isExpanded: false,
          child: Column(
            children: [
              TextField(
                controller: _previewInputController,
                decoration: const InputDecoration(
                  labelText: 'Nhap cau giao dich de test',
                  hintText: 'Vi du: me cho 2 trieu, mua tra sua 45k',
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
                    label: const Text('Phan tich'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _previewResult = null;
                        _previewMessage = null;
                      });
                    },
                    child: const Text('Xoa xem truoc'),
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
        ),
        const SizedBox(height: 18),
        AdminPanel(
          title: 'File he thong',
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
              _CountPill(label: '${section.values.length} tu'),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Sua'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onDelete,
                child: const Text('Xoa'),
              ),
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
          if (section.values.length > 24) ...[
            const SizedBox(height: 10),
            Text(
              '+ ${section.values.length - 24} tu khoa nua',
              style: const TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
        child: const Text('Chua co ket qua xem truoc.'),
      );
    }

    final status = _statusLabel(result!['status']?.toString() ?? 'unknown');
    final message = result!['message']?.toString() ?? '';
    final transactions =
        (result!['transactions'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();

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
              Row(
                children: [
                  _CountPill(label: status),
                  const SizedBox(width: 8),
                  _CountPill(label: '${transactions.length} giao dich'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message,
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
            child: Text('Khong co giao dich nao duoc tach ra.'),
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
                            item['title']?.toString() ?? 'Khong co tieu de',
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
                          label: 'Loai: ${_typeLabel(item['type']?.toString() ?? '')}',
                        ),
                        _CountPill(label: 'Danh muc: ${item['category'] ?? ''}'),
                        _CountPill(
                          label: 'Do tin cay: ${_confidenceLabel(item['confidenceLabel']?.toString() ?? '')}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ghi chu: ${item['note'] ?? ''}',
                      style: const TextStyle(color: Color(0xFF475467)),
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
                'data.text / file dai dien he thong',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'File nay chi de doi chieu va xem noi dung goc. Khong sua truc tiep, khong xoa truc tiep de tranh lam mat chuc nang AI.',
            style: const TextStyle(
              color: Color(0xFF667085),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CountPill(label: 'Nguon: $source'),
              _CountPill(label: '$lineCount dong'),
              _CountPill(label: '${raw.length} ky tu'),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onView,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Xem file he thong'),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String value) {
  switch (value) {
    case 'success':
      return 'Thanh cong';
    case 'clarification':
      return 'Can lam ro';
    case 'error':
      return 'Loi';
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

String _confidenceLabel(String value) {
  switch (value.toLowerCase()) {
    case 'high':
      return 'Cao';
    case 'medium':
      return 'Trung binh';
    case 'low':
      return 'Thap';
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
        boxShadow: [
          BoxShadow(
            color: group.tint.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: group.tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            group.value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
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
  const _LexiconSection({
    required this.key,
    required this.values,
  });

  final String key;
  final List<String> values;
}
